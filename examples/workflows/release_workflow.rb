require 'activities/echo_activity'

class ReleaseWorkflow < Temporal::Workflow
  def execute(sleep_seconds)
    if sleep_seconds <= 0
      raise 'ReleaseWorkflow takes one argument which must be a positive number of seconds to sleep'
    end

    EchoActivity.execute!('Original activity 1')

    if workflow.has_release?(:fix_1)
      EchoActivity.execute!('Added activity 1')
    end

    workflow.sleep(sleep_seconds)

    if workflow.has_release?(:fix_1)
      EchoActivity.execute!('Added activity 2')
    else
      EchoActivity.execute!('Original removed activity')
    end

    workflow.sleep(sleep_seconds)

    if workflow.has_release?(:fix_2)
      EchoActivity.execute!('Added activity 3')
    end

    return
  end
end
