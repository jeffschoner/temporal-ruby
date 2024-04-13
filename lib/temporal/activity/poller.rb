require 'temporal/activity/task_processor'
require 'temporal/connection'
require 'temporal/error_handler'
require 'temporal/metric_keys'
require 'temporal/middleware/chain'
require 'temporal/thread_pool'

module Temporal
  class Activity
    class Poller
      DEFAULT_OPTIONS = {
        task_slots: 20,
        poll_retry_seconds: 0
      }.freeze

      def initialize(namespace, task_queue, activity_lookup, config, thread_pool, middleware = [], options = {})
        @namespace = namespace
        @task_queue = task_queue
        @activity_lookup = activity_lookup
        @config = config
        @thread_pool = thread_pool
        @middleware = middleware
        @shutting_down = false
        @options = DEFAULT_OPTIONS.merge(options)
        @mutex = Mutex.new
        @slot_available = ConditionVariable.new
        @available_slots = @options[:task_slots]
      end

      def start
        @shutting_down = false
        @thread = Thread.new(&method(:poll_loop))
      end

      def stop_polling
        @shutting_down = true
        Temporal.logger.info('Shutting down activity poller', { namespace: namespace, task_queue: task_queue })
      end

      def cancel_pending_requests
        connection.cancel_polling_request
      end

      def wait
        if !shutting_down?
          raise "Activity poller waiting for shutdown completion without being in shutting_down state!"
        end

        thread.join
      end

      private

      attr_reader :namespace, :task_queue, :activity_lookup, :config, :middleware, :options, :thread, :thread_pool,
                  :mutex, :slot_available

      def connection
        @connection ||= Temporal::Connection.generate(config.for_connection)
      end

      def shutting_down?
        @shutting_down
      end

      def poll_loop
        # Prevent the poller thread from silently dying
        Thread.current.abort_on_exception = true

        last_poll_time = Time.now
        metrics_tags = { namespace: namespace, task_queue: task_queue }.freeze

        loop do
          mutex.synchronize do
            while @available_slots <= 0
              slot_available.wait(mutex)
            end

            @available_slots -= 1
          end

          return if shutting_down?

          time_diff_ms = ((Time.now - last_poll_time) * 1000).round
          Temporal.metrics.timing(Temporal::MetricKeys::ACTIVITY_POLLER_TIME_SINCE_LAST_POLL, time_diff_ms, metrics_tags)
          Temporal.logger.debug("Polling activity task queue", { namespace: namespace, task_queue: task_queue })

          task = poll_for_task
          last_poll_time = Time.now

          Temporal.metrics.increment(
            Temporal::MetricKeys::ACTIVITY_POLLER_POLL_COMPLETED,
            metrics_tags.merge(received_task: (!task.nil?).to_s)
          )

          if !task&.activity_type
            mutex.synchronize do
              @available_slots += 1
            end
            next
          end

          thread_pool.schedule do
            process(task)

            mutex.synchronize do
              @available_slots += 1
              slot_available.signal
            end
          end
        end
      end

      def poll_for_task
        connection.poll_activity_task_queue(namespace: namespace, task_queue: task_queue)
      rescue ::GRPC::Cancelled
        # We're shutting down and we've already reported that in the logs
        nil
      rescue StandardError => error
        Temporal.logger.error("Unable to poll activity task queue", { namespace: namespace, task_queue: task_queue, error: error.inspect })

        Temporal::ErrorHandler.handle(error, config)

        sleep(poll_retry_seconds)

        nil
      end

      def process(task)
        middleware_chain = Middleware::Chain.new(middleware)

        TaskProcessor.new(task, task_queue, namespace, activity_lookup, middleware_chain, config, thread_pool).process
      end

      def poll_retry_seconds
        @options[:poll_retry_seconds]
      end
    end
  end
end
