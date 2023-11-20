require 'activities/hello_world_activity'

class CancelWorkflow < Temporal::Workflow
  def execute(timeout)
    canceled_reason = nil
    timer = workflow.start_timer(timeout)
    workflow.on_cancel do |reason|
      HelloWorldActivity.execute!("got canceled due to '#{reason}'")

      # The return value will be captured in the WorkflowExecutionCanceled event
      'ran HelloWorldActivity'
    end

    timer.wait

    return
  end
end
