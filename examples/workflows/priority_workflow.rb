require 'activities/hello_world_activity'

class PriorityWorkflow < Temporal::Workflow
  def execute(important = false)
    return HelloWorldActivity.execute!('somebody', options: { priority_key: important ? 1 : 5 })
  end
end
