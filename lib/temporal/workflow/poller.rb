require 'grpc/errors'
require 'temporal/connection'
require 'temporal/thread_pool'
require 'temporal/middleware/chain'
require 'temporal/workflow/executor_cache'
require 'temporal/workflow/task_processor'
require 'temporal/error_handler'
require 'temporal/metric_keys'

module Temporal
  class Workflow
    class Poller
      DEFAULT_OPTIONS = {
        thread_pool_size: 10,
        binary_checksum: nil,
        poll_retry_seconds: 0
      }.freeze

      def initialize(namespace, task_queue, workflow_lookup, config, middleware = [], workflow_middleware = [], options = {})
        @namespace = namespace
        @task_queue = task_queue
        @workflow_lookup = workflow_lookup
        @config = config
        @middleware = middleware
        @workflow_middleware = workflow_middleware
        @shutting_down = false
        @options = DEFAULT_OPTIONS.merge(options)

        if config.use_sticky_task_queues
          @sticky_task_queue = "#{config.identity}:#{SecureRandom.uuid}"
          @executor_cache = Temporal::Workflow::ExecutorCache.new
        else
          @sticky_task_queue = nil
          @executor_cache = nil
        end
      end

      def start
        @shutting_down = false
        @thread = Thread.new { poll_loop(sticky: false) }
        if sticky_task_queue
          @sticky_thread = Thread.new { poll_loop(sticky: true) }
        else
          @sticky_thread = nil
        end
      end

      def stop_polling
        @shutting_down = true
        Temporal.logger.info('Shutting down a workflow poller', { namespace: namespace, task_queue: task_queue })
      end

      def cancel_pending_requests
        connection.cancel_polling_request
      end

      def wait
        if !shutting_down?
          raise "Workflow poller waiting for shutdown completion without being in shutting_down state!"
        end

        thread.join
        sticky_thread.join unless sticky_thread.nil?
        thread_pool.shutdown
      end

      private

      attr_reader :namespace, :task_queue, :connection, :workflow_lookup, :config, :middleware, :workflow_middleware,
        :options, :thread, :sticky_thread, :sticky_task_queue

      def connection
        @connection ||= Temporal::Connection.generate(config.for_connection)
      end

      def shutting_down?
        @shutting_down
      end

      def poll_loop(sticky:)
        last_poll_time = Time.now
        metrics_tags = { namespace: namespace, task_queue: task_queue, sticky: sticky }.freeze

        loop do
          thread_pool.wait_for_available_threads

          return if shutting_down?

          time_diff_ms = ((Time.now - last_poll_time) * 1000).round
          Temporal.metrics.timing(Temporal::MetricKeys::WORKFLOW_POLLER_TIME_SINCE_LAST_POLL, time_diff_ms, metrics_tags)
          Temporal.logger.debug("Polling workflow task queue", {
            namespace: namespace,
            task_queue: task_queue,
            sticky: sticky ? sticky_task_queue : nil
          })

          task = poll_for_task(sticky: sticky)
          last_poll_time = Time.now

          Temporal.metrics.increment(
            Temporal::MetricKeys::WORKFLOW_POLLER_POLL_COMPLETED,
            metrics_tags.merge(received_task: (!task.nil?).to_s)
          )

          next unless task&.workflow_type

          thread_pool.schedule { process(task, sticky) }
        end
      end

      def poll_for_task(sticky:)
        connection.poll_workflow_task_queue(
          namespace: namespace,
          task_queue: task_queue,
          binary_checksum: binary_checksum,
          sticky_task_queue: sticky ? sticky_task_queue : nil
        )
      rescue ::GRPC::Cancelled
        # We're shutting down and we've already reported that in the logs
        nil
      rescue StandardError => error
        Temporal.logger.error("Unable to poll Workflow task queue", { namespace: namespace, task_queue: task_queue, sticky: sticky ? sticky_task_queue : nil, error: error.inspect })
        Temporal::ErrorHandler.handle(error, config)

        sleep(poll_retry_seconds)

        nil
      end

      def process(task, sticky)
        middleware_chain = Middleware::Chain.new(middleware)
        workflow_middleware_chain = Middleware::Chain.new(workflow_middleware)

        TaskProcessor.new(task, namespace, workflow_lookup, middleware_chain, workflow_middleware_chain, config, binary_checksum, executor_cache, task_queue, sticky_task_queue).process
      end

      def thread_pool
        @thread_pool ||= ThreadPool.new(
          options[:thread_pool_size],
          {
            pool_name: 'workflow_task_poller',
            namespace: namespace,
            task_queue: task_queue
          }
        )
      end

      def binary_checksum
        @options[:binary_checksum]
      end

      def poll_retry_seconds
        @options[:poll_retry_seconds]
      end
    end
  end
end
