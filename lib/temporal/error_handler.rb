module Temporal
  module ErrorHandler
    def self.handle(error, configuration, metadata: nil)
      configuration.error_handlers.each do |handler|
        handler.call(error, metadata: metadata)
      rescue Temporal::ActivityInterruptedError
        # These errors are used for flow control and should not be reported
      rescue StandardError => e
        Temporal.logger.error("Error handler failed", { error: e.inspect })
      end
    end
  end
end
