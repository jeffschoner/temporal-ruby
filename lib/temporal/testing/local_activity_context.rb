require 'securerandom'
require 'temporal/uuid'
require 'temporal/activity/context'

module Temporal
  module Testing
    class LocalActivityContext < Activity::Context
      def initialize(metadata)
        super(nil, metadata, nil, nil, proc { false })
      end

      def heartbeat(details = nil, **kwargs)
        # behavior is not yet testable in local mode
      end
    end
  end
end
