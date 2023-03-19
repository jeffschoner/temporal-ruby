require 'activities/echo_activity'

class PatchWorkflow < Temporal::Workflow
  def execute(sleep_seconds)
    if sleep_seconds <= 0
      raise 'PatchWorkflow takes one argument which must be a positive number of seconds to sleep'
    end

    EchoActivity.execute!('Original activity 1')

    if workflow.patched?(:fix_1)
      EchoActivity.execute!('Added activity 1')
    end

    workflow.sleep(sleep_seconds)

    if workflow.patched?(:fix_1)
      EchoActivity.execute!('Added activity 2')
    else
      EchoActivity.execute!('Original removed activity')
    end

    workflow.sleep(sleep_seconds)

    if workflow.patched?(:fix_2)
      EchoActivity.execute!('Added activity 3')
    end

    workflow.deprecate_patch(:fix3)

    return
  end
end
