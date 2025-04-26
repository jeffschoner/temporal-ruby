require 'workflows/priority_workflow'

describe PriorityWorkflow do
  subject { described_class }

  it 'executes with priority' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      PriorityWorkflow,
      true,
      options: { workflow_id: workflow_id, priority_key: 4 },
    )
    Temporal.await_workflow_result(
      PriorityWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
    execution_info = Temporal.fetch_workflow_execution_info('ruby-samples', workflow_id, run_id)
    expect(execution_info.priority_key).to eq(4)
  end
end
