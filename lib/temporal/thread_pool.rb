require 'temporal/errors'
require 'temporal/metric_keys'

# This class implements a ThreadPool with the ability to block until at least one thread
# becomes available. This allows Pollers to only poll when there's an available thread
# in the pool.
#
# NOTE: There's a minor race condition that can occur between calling
#       #wait_for_available_threads and #schedule, but should be rare
#
module Temporal
  class ThreadPool
    attr_reader :size

    def initialize(size, cancelable, config, metrics_tags)
      @size = size
      @metrics_tags = metrics_tags
      @queue = Queue.new
      @mutex = Mutex.new
      @config = config
      @availability = ConditionVariable.new
      @available_threads = size
      @pool = Array.new(size) do |_i|
        Thread.new { poll }
      end
      @cancelable = cancelable
      @shutting_down = nil
    end

    def report_metrics
      Temporal.metrics.gauge(Temporal::MetricKeys::THREAD_POOL_AVAILABLE_THREADS, @available_threads, @metrics_tags)
    end

    def wait_for_available_threads
      @mutex.synchronize do
        @availability.wait(@mutex) while @available_threads <= 0
      end
    end

    def schedule(delay = 0, &block)
      item = Item.new(block, delay, @cancelable)

      @mutex.synchronize do
        @available_threads -= 1
        @queue << item
      end

      report_metrics

      item
    end

    def shutdown
      # If we don't wait, the thread pool will be shut down without all tasks received from Temporal
      # server having been processed. Without this, eventually the associated task will time out,
      # but this could take a while and lead to unnecessary failures when the retry policy does not
      # allow for another attempt.
      @mutex.synchronize do
        @shutting_down = ConditionVariable.new
        until @queue.empty?
          @shutting_down.wait(@mutex)
        end
      end

      @pool.each do |thread|
        thread.raise(WorkerShuttingDownError.new)
      end

      @pool.each do |thread|
        begin
          thread.join
        rescue WorkerShuttingDownError
          # This should almost never happen, but can safely be ignored. It can occur if a thread pool is
          # shutdown immediately after it is started. In this case, the WorkerShuttingDownError could
          # be raised into the thread before it has entered the handle_interrupt(:never) block.
        end
      end
    end

    private

    class Item
      def initialize(job, delay, cancelable)
        @job = job
        @fire_at = if delay > 0
          Time.now + delay
        else
          nil
        end
        @canceled = false
        @assigned_thread = nil
        @mutex = cancelable ? Mutex.new : nil
      end

      attr_reader :canceled

      def cancel
        raise ActivityInterruptedError.new("Items from this thread pool are not cancelable") if @mutex.nil?

        @mutex.synchronize do
          return if @canceled

          @canceled = true
          unless @assigned_thread.nil?
            @assigned_thread.raise(CancelError.new)
          end
        end
      end

      def assign
        return if @mutex.nil?

        @mutex.synchronize do
          return if @canceled

          @assigned_thread = Thread.current
        end
      end

      def sleep_for_delay
        return if @canceled || @fire_at.nil?

        delay = @fire_at - Time.now
        if delay > 0
          sleep delay
        end
      end

      def call_job
        return if @canceled

        @job.call
      end
    end

    def poll
      Thread.current.abort_on_exception = true
      begin
        # Nest handle_interrupt blocks so that this code can only be interrupted in 3 places:
        # 1. While waiting on a new item from the queue
        # 2. Job code itself that has opted into being interrupted by ActivityInterruptedError
        # 3. Right before exiting
        Thread.handle_interrupt(ActivityInterruptedError => :never) do
          loop do
            item = nil
            Thread.handle_interrupt(ActivityInterruptedError => :immediate) do
              item = @queue.pop
              @mutex.synchronize do
                @shutting_down&.signal
              end
              item.assign
              item.sleep_for_delay
            end

            # Include this in the begin/rescue block for CancelError because jobs can
            # opt into being cancelable by adding their own Thread.handle_interrupt
            # block or have these errors raised when calling .heartbeat.
            item.call_job

            @mutex.synchronize do
              @available_threads += 1
              @availability.signal
            end

            report_metrics
          end
        end
      rescue Temporal::ActivityCanceled
        # Ignore these errors because this should only occur if it was raised on a thread that
        # is already exiting
      rescue Temporal::WorkerShuttingDownError
        # Ignore these errors since it requests that the thread shuts down which it will
        # do upon returning
      rescue StandardError => e
        Temporal.logger.error('Error reached top of thread pool thread', { error: e.inspect })
        Temporal::ErrorHandler.handle(e, @config)
      rescue Exception => ex
        Temporal.logger.error('Exception reached top of thread pool thread', { error: ex.inspect })
        Temporal::ErrorHandler.handle(ex, @config)
        raise
      end
    end
  end
end
