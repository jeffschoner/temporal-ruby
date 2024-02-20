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

  # Represents cancellation of a non-started activity
  class ActivityCanceled < ActivityException; end

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

  # Thread pool related errors

  # If you are ok with your activity code being interrupted, you can add a Thread.handle_interrupt
  # block for these error types.
  class ThreadPoolError < Error; end

  # This is raised when an activity is canceled. This can occur when the activity heartbeats
  # on a background thread, and discovers the activity has been canceled on Temporal server.
  class CancelError < ThreadPoolError; end

  # This is raised when the thread pool is shutting down as part of worker shutdown. This
  # typically occurs when the worker receives a TERM or INT signal.
  class ExitError < ThreadPoolError; end

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
