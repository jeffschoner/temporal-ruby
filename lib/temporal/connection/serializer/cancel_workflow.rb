require 'temporal/connection/serializer/base'
require 'temporal/concerns/payloads'

module Temporal
  module Connection
    module Serializer
      class CancelWorkflow < Base
        include Concerns::Payloads

        def to_proto
          Temporalio::Api::Command::V1::Command.new(
            command_type: Temporalio::Api::Enums::V1::CommandType::COMMAND_TYPE_CANCEL_WORKFLOW_EXECUTION,
            cancel_workflow_execution_command_attributes:
              Temporalio::Api::Command::V1::CancelWorkflowExecutionCommandAttributes.new(
                details: to_result_payloads(object.details)
              )
          )
        end
      end
    end
  end
end
