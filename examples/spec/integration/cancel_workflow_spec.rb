require 'securerandom'
require 'workflows/cancel_workflow'

describe 'cancel' do
  it 'workflow cancels' do
    workflow_id = SecureRandom.uuid
    run_id = Temporal.start_workflow(
      CancelWorkflow,
      30, # seconds
      options: {
        workflow_id: workflow_id,
        timeouts: { execution: 60 }
      }
    )

    # wait a bit for the first workflow task to start
    sleep 0.5
    Temporal.cancel_workflow(workflow_id, reason: 'because')

    expect do
      Temporal.await_workflow_result(
        CancelWorkflow,
        workflow_id: workflow_id,
        run_id: run_id
      )
    end.to raise_error(Temporal::WorkflowCanceled) do |e|
      expect(e.details).to eq("ran HelloWorldActivity")
    end
  end
end
