# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: temporal/api/enums/v1/failed_cause.proto

require 'google/protobuf'


descriptor_data = "\n(temporal/api/enums/v1/failed_cause.proto\x12\x15temporal.api.enums.v1*\xdf\x0f\n\x17WorkflowTaskFailedCause\x12*\n&WORKFLOW_TASK_FAILED_CAUSE_UNSPECIFIED\x10\x00\x12\x30\n,WORKFLOW_TASK_FAILED_CAUSE_UNHANDLED_COMMAND\x10\x01\x12?\n;WORKFLOW_TASK_FAILED_CAUSE_BAD_SCHEDULE_ACTIVITY_ATTRIBUTES\x10\x02\x12\x45\nAWORKFLOW_TASK_FAILED_CAUSE_BAD_REQUEST_CANCEL_ACTIVITY_ATTRIBUTES\x10\x03\x12\x39\n5WORKFLOW_TASK_FAILED_CAUSE_BAD_START_TIMER_ATTRIBUTES\x10\x04\x12:\n6WORKFLOW_TASK_FAILED_CAUSE_BAD_CANCEL_TIMER_ATTRIBUTES\x10\x05\x12;\n7WORKFLOW_TASK_FAILED_CAUSE_BAD_RECORD_MARKER_ATTRIBUTES\x10\x06\x12I\nEWORKFLOW_TASK_FAILED_CAUSE_BAD_COMPLETE_WORKFLOW_EXECUTION_ATTRIBUTES\x10\x07\x12\x45\nAWORKFLOW_TASK_FAILED_CAUSE_BAD_FAIL_WORKFLOW_EXECUTION_ATTRIBUTES\x10\x08\x12G\nCWORKFLOW_TASK_FAILED_CAUSE_BAD_CANCEL_WORKFLOW_EXECUTION_ATTRIBUTES\x10\t\x12X\nTWORKFLOW_TASK_FAILED_CAUSE_BAD_REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION_ATTRIBUTES\x10\n\x12=\n9WORKFLOW_TASK_FAILED_CAUSE_BAD_CONTINUE_AS_NEW_ATTRIBUTES\x10\x0b\x12\x37\n3WORKFLOW_TASK_FAILED_CAUSE_START_TIMER_DUPLICATE_ID\x10\x0c\x12\x36\n2WORKFLOW_TASK_FAILED_CAUSE_RESET_STICKY_TASK_QUEUE\x10\r\x12@\n<WORKFLOW_TASK_FAILED_CAUSE_WORKFLOW_WORKER_UNHANDLED_FAILURE\x10\x0e\x12G\nCWORKFLOW_TASK_FAILED_CAUSE_BAD_SIGNAL_WORKFLOW_EXECUTION_ATTRIBUTES\x10\x0f\x12\x43\n?WORKFLOW_TASK_FAILED_CAUSE_BAD_START_CHILD_EXECUTION_ATTRIBUTES\x10\x10\x12\x32\n.WORKFLOW_TASK_FAILED_CAUSE_FORCE_CLOSE_COMMAND\x10\x11\x12\x35\n1WORKFLOW_TASK_FAILED_CAUSE_FAILOVER_CLOSE_COMMAND\x10\x12\x12\x34\n0WORKFLOW_TASK_FAILED_CAUSE_BAD_SIGNAL_INPUT_SIZE\x10\x13\x12-\n)WORKFLOW_TASK_FAILED_CAUSE_RESET_WORKFLOW\x10\x14\x12)\n%WORKFLOW_TASK_FAILED_CAUSE_BAD_BINARY\x10\x15\x12=\n9WORKFLOW_TASK_FAILED_CAUSE_SCHEDULE_ACTIVITY_DUPLICATE_ID\x10\x16\x12\x34\n0WORKFLOW_TASK_FAILED_CAUSE_BAD_SEARCH_ATTRIBUTES\x10\x17\x12\x36\n2WORKFLOW_TASK_FAILED_CAUSE_NON_DETERMINISTIC_ERROR\x10\x18\x12H\nDWORKFLOW_TASK_FAILED_CAUSE_BAD_MODIFY_WORKFLOW_PROPERTIES_ATTRIBUTES\x10\x19\x12\x45\nAWORKFLOW_TASK_FAILED_CAUSE_PENDING_CHILD_WORKFLOWS_LIMIT_EXCEEDED\x10\x1a\x12@\n<WORKFLOW_TASK_FAILED_CAUSE_PENDING_ACTIVITIES_LIMIT_EXCEEDED\x10\x1b\x12=\n9WORKFLOW_TASK_FAILED_CAUSE_PENDING_SIGNALS_LIMIT_EXCEEDED\x10\x1c\x12\x44\n@WORKFLOW_TASK_FAILED_CAUSE_PENDING_REQUEST_CANCEL_LIMIT_EXCEEDED\x10\x1d\x12\x44\n@WORKFLOW_TASK_FAILED_CAUSE_BAD_UPDATE_WORKFLOW_EXECUTION_MESSAGE\x10\x1e\x12/\n+WORKFLOW_TASK_FAILED_CAUSE_UNHANDLED_UPDATE\x10\x1f*\xf3\x01\n&StartChildWorkflowExecutionFailedCause\x12;\n7START_CHILD_WORKFLOW_EXECUTION_FAILED_CAUSE_UNSPECIFIED\x10\x00\x12G\nCSTART_CHILD_WORKFLOW_EXECUTION_FAILED_CAUSE_WORKFLOW_ALREADY_EXISTS\x10\x01\x12\x43\n?START_CHILD_WORKFLOW_EXECUTION_FAILED_CAUSE_NAMESPACE_NOT_FOUND\x10\x02*\x91\x02\n*CancelExternalWorkflowExecutionFailedCause\x12?\n;CANCEL_EXTERNAL_WORKFLOW_EXECUTION_FAILED_CAUSE_UNSPECIFIED\x10\x00\x12Y\nUCANCEL_EXTERNAL_WORKFLOW_EXECUTION_FAILED_CAUSE_EXTERNAL_WORKFLOW_EXECUTION_NOT_FOUND\x10\x01\x12G\nCCANCEL_EXTERNAL_WORKFLOW_EXECUTION_FAILED_CAUSE_NAMESPACE_NOT_FOUND\x10\x02*\xe2\x02\n*SignalExternalWorkflowExecutionFailedCause\x12?\n;SIGNAL_EXTERNAL_WORKFLOW_EXECUTION_FAILED_CAUSE_UNSPECIFIED\x10\x00\x12Y\nUSIGNAL_EXTERNAL_WORKFLOW_EXECUTION_FAILED_CAUSE_EXTERNAL_WORKFLOW_EXECUTION_NOT_FOUND\x10\x01\x12G\nCSIGNAL_EXTERNAL_WORKFLOW_EXECUTION_FAILED_CAUSE_NAMESPACE_NOT_FOUND\x10\x02\x12O\nKSIGNAL_EXTERNAL_WORKFLOW_EXECUTION_FAILED_CAUSE_SIGNAL_COUNT_LIMIT_EXCEEDED\x10\x03*\xa5\x02\n\x16ResourceExhaustedCause\x12(\n$RESOURCE_EXHAUSTED_CAUSE_UNSPECIFIED\x10\x00\x12&\n\"RESOURCE_EXHAUSTED_CAUSE_RPS_LIMIT\x10\x01\x12-\n)RESOURCE_EXHAUSTED_CAUSE_CONCURRENT_LIMIT\x10\x02\x12.\n*RESOURCE_EXHAUSTED_CAUSE_SYSTEM_OVERLOADED\x10\x03\x12.\n*RESOURCE_EXHAUSTED_CAUSE_PERSISTENCE_LIMIT\x10\x04\x12*\n&RESOURCE_EXHAUSTED_CAUSE_BUSY_WORKFLOW\x10\x05\x42\x88\x01\n\x18io.temporal.api.enums.v1B\x10\x46\x61iledCauseProtoP\x01Z!go.temporal.io/api/enums/v1;enums\xaa\x02\x17Temporalio.Api.Enums.V1\xea\x02\x1aTemporalio::Api::Enums::V1b\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Temporalio
  module Api
    module Enums
      module V1
        WorkflowTaskFailedCause = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.enums.v1.WorkflowTaskFailedCause").enummodule
        StartChildWorkflowExecutionFailedCause = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.enums.v1.StartChildWorkflowExecutionFailedCause").enummodule
        CancelExternalWorkflowExecutionFailedCause = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.enums.v1.CancelExternalWorkflowExecutionFailedCause").enummodule
        SignalExternalWorkflowExecutionFailedCause = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.enums.v1.SignalExternalWorkflowExecutionFailedCause").enummodule
        ResourceExhaustedCause = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("temporal.api.enums.v1.ResourceExhaustedCause").enummodule
      end
    end
  end
end
