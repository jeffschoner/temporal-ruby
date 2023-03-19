require 'workflows/patch_workflow'

describe PatchWorkflow do
  it 'can complete a workflow with patches' do
    workflow_id = SecureRandom.uuid

    run_id = Temporal.start_workflow(
      PatchWorkflow,
      1,
      options: {
        workflow_id: workflow_id,
      },
    )

    Temporal.await_workflow_result(
      PatchWorkflow,
      workflow_id: workflow_id,
      run_id: run_id,
    )
  end
end
