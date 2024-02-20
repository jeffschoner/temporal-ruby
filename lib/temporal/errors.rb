module Temporal
  # Superclass for all Temporal errors
  class Error < StandardError; end

  # Superclass for errors specific to Temporal worker itself
  class InternalError < Error; end

  # Indicates a non-deterministic workflow execution, might be due to
  # a non-deterministic workflow implementation or the gem's bug
  class NonDeterministicWorkflowError < InternalError; end

  # Indicates a workflow task was encountered that used an unknown SDK flag
  class UnknownSDKFlagError < InternalError; end

  # Superclass for misconfiguration/misuse on the client (user) side
  class ClientError < Error; end

  # Represents any timeout
  class TimeoutError < ClientError; end

  # Represents when a child workflow times out
  class ChildWorkflowTimeoutError < Error; end

  # Represents when a child workflow is terminated
  class ChildWorkflowTerminatedError < Error; end

  # A superclass for activity exceptions raised explicitly
  # with the intent to propagate to a workflow
  # With v2 serialization (set with Temporal.configuration set with use_error_serialization_v2=true) you can
  # throw any exception from an activity and expect that it can be handled by the workflow.
  class ActivityException < ClientError; end

  # Superclass used to cover a set of errors that can be raised that interrupt an activity's
  # execution. You typically use this through Thread.handle_interrupt(ActivityInterruptedError => :immediate)
  # to allow your activity to raise this error during safe points in its execution.
  class ActivityInterruptedError < ActivityException; end

  # Represents cancellation of an activity. This can appear in two ways:
  #
  # In activities: When the workflow has requested an activity's cancellation and the
  # activity heartbeats. If this error is raised out of an activity, it will be put
  # into a canceled state.
  #
  # In workflows: When a canceled activity's result is requested.
  class ActivityCanceled < ActivityInterruptedError; end

  class ActivityNotRegistered < ClientError; end
  class WorkflowNotRegistered < ClientError; end
  class SecondDynamicActivityError < ClientError; end
  class SecondDynamicWorkflowError < ClientError; end

  class ApiError < Error; end

  class NotFoundFailure < ApiError; end

  # Superclass for system errors raised when retrieving a workflow result on the
  # client, but the workflow failed remotely.
  class WorkflowError < Error; end

  class WorkflowTimedOut < WorkflowError; end
  class WorkflowTerminated < WorkflowError; end
  class WorkflowCanceled < WorkflowError; end

  # This can be raised into activity code when the worker executing an activity attempt is
  # shutting down. By default, your code will not be interrupted. You need to opt-in by
  # wrapping your code in a Thread.handle_interrupt block for this type
  # (or ActivityInterruptedError).
  class WorkerShuttingDownError < ActivityInterruptedError; end

  # Errors where the workflow run didn't complete but not an error for the whole workflow.
  class WorkflowRunError < Error; end

  class WorkflowRunContinuedAsNew < WorkflowRunError
    attr_reader :new_run_id

    def initialize(new_run_id:)
      super
      @new_run_id = new_run_id
    end
  end

  # Once the workflow succeeds, fails, or continues as new, you can't issue any other commands such as
  # scheduling an activity.  This error is thrown if you try, before we report completion back to the server.
  # This could happen due to activity futures that aren't awaited before the workflow closes,
  # calling workflow.continue_as_new, workflow.complete, or workflow.fail in the middle of your workflow code,
  # or an internal framework bug.
  class WorkflowAlreadyCompletingError < InternalError; end

  class WorkflowExecutionAlreadyStartedFailure < ApiError
    attr_reader :run_id

    def initialize(message, run_id = nil)
      super(message)
      @run_id = run_id
    end
  end

  class NamespaceNotActiveFailure < ApiError; end
  class ClientVersionNotSupportedFailure < ApiError; end
  class FeatureVersionNotSupportedFailure < ApiError; end
  class NamespaceAlreadyExistsFailure < ApiError; end
  class CancellationAlreadyRequestedFailure < ApiError; end
  class QueryFailed < ApiError; end

  class SearchAttributeAlreadyExistsFailure < ApiError; end
  class SearchAttributeFailure < ApiError; end
  class InvalidSearchAttributeTypeFailure < ClientError; end
end
