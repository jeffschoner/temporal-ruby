require 'temporal/activity/context'
require 'temporal/metadata/activity'
require 'temporal/scheduled_thread_pool'

describe Temporal::Activity::Context do
  let(:client) { instance_double('Temporal::Client::GRPCClient') }
  let(:metadata_hash) { Fabricate(:activity_metadata).to_h }
  let(:metadata) { Temporal::Metadata::Activity.new(**metadata_hash) }
  let(:config) { Temporal::Configuration.new }
  let(:task_token) { SecureRandom.uuid }
  let(:heartbeat_thread_pool) { Temporal::ScheduledThreadPool.new(1, {}) }
  let(:heartbeat_response) { Fabricate(:api_record_activity_heartbeat_response) }
  let(:is_shutting_down_proc) { proc { false } }

  subject { described_class.new(client, metadata, config, heartbeat_thread_pool, is_shutting_down_proc) }

  describe '#heartbeat' do
    before { allow(client).to receive(:record_activity_task_heartbeat).and_return(heartbeat_response) }

    it 'records heartbeat' do
      subject.heartbeat

      expect(client)
        .to have_received(:record_activity_task_heartbeat)
        .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)
    end

    it 'records heartbeat with details' do
      subject.heartbeat(foo: :bar)

      expect(client)
        .to have_received(:record_activity_task_heartbeat)
        .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { foo: :bar })
    end

    context 'cancellation' do
      let(:heartbeat_response) { Fabricate(:api_record_activity_heartbeat_response, cancel_requested: true) }
      it 'sets when cancelled' do
        subject.heartbeat
        expect(subject.cancel_requested).to be(true)
      end
    end

    context 'throttling' do
      context 'skips after the first heartbeat' do
        let(:metadata_hash) { Fabricate(:activity_metadata, heartbeat_timeout: 30).to_h }
        it 'discard duplicates after first when quickly completes' do
          10.times do |i|
            subject.heartbeat(iteration: i)
          end

          expect(client)
            .to have_received(:record_activity_task_heartbeat)
            .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { iteration: 0 })
            .once
        end
      end

      context 'resumes' do
        let(:metadata_hash) { Fabricate(:activity_metadata, heartbeat_timeout: 0.1).to_h }
        it 'more heartbeats after time passes' do
          subject.heartbeat(iteration: 1)
          subject.heartbeat(iteration: 2) # skipped because 3 will overwrite
          subject.heartbeat(iteration: 3)
          sleep 0.1
          subject.heartbeat(iteration: 4)

          # Shutdown to drain remaining threads
          heartbeat_thread_pool.shutdown

          expect(client)
            .to have_received(:record_activity_task_heartbeat)
            .ordered
            .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { iteration: 1 })
            .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { iteration: 3 })
            .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { iteration: 4 })
        end
      end

      it 'no heartbeat check scheduled when max interval is zero' do
        config.timeouts = { max_heartbeat_throttle_interval: 0 }
      end
    end

    it 'not interrupted, raise flag true' do
      subject.heartbeat(raise_when_interrupted: true)

      expect(client)
        .to have_received(:record_activity_task_heartbeat)
        .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)
    end

    it 'not interrupted, raise flag true, with details' do
      subject.heartbeat(foo: :bar, raise_when_interrupted: true)

      expect(client)
        .to have_received(:record_activity_task_heartbeat)
        .with(namespace: metadata.namespace, task_token: metadata.task_token, details: { foo: :bar })
    end

    describe 'timed out' do
      let(:metadata_hash) { Fabricate(:activity_metadata, start_to_close_timeout: 0.1).to_h }

      it 'interrupted, raise flag true' do
        subject.heartbeat(raise_when_interrupted: true)
        expect(client)
          .to have_received(:record_activity_task_heartbeat)
          .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)

        sleep 0.1
        expect do
          subject.heartbeat(raise_when_interrupted: true)
        end.to raise_error(Temporal::ActivityExecutionTimedOut)
      end

      it 'not interrupted, raise flag false' do
        subject.heartbeat
        sleep 0.1
        subject.heartbeat

        expect(client)
          .to have_received(:record_activity_task_heartbeat)
          .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)
      end
    end
  end

  describe '#last_heartbeat_throttled' do
    before { allow(client).to receive(:record_activity_task_heartbeat).and_return(heartbeat_response) }

    let(:metadata_hash) { Fabricate(:activity_metadata, heartbeat_timeout: 10).to_h }

    it 'true when throttled, false when not' do
      subject.heartbeat(iteration: 1)
      expect(subject.last_heartbeat_throttled).to be(false)
      subject.heartbeat(iteration: 2)
      expect(subject.last_heartbeat_throttled).to be(true)
      subject.heartbeat(iteration: 3)
      expect(subject.last_heartbeat_throttled).to be(true)
    end

    context 'start to close timeout' do
      let(:metadata_hash) { Fabricate(:activity_metadata, start_to_close_timeout: 0.01).to_h }
      it 'timed_out? true when start to close exceeded' do
        expect(subject.timed_out?).to be(false)
        sleep 0.01
        expect do
          subject.heartbeat
        end
        expect(subject.timed_out?).to be(true)
      end
    end

    describe 'canceled' do
      let(:heartbeat_response) { Fabricate(:api_record_activity_heartbeat_response, cancel_requested: true) }

      it 'interrupted, raise flag true' do
        expect do
          subject.heartbeat(raise_when_interrupted: true)
        end.to raise_error(Temporal::ActivityExecutionCanceled)

        expect(client)
          .to have_received(:record_activity_task_heartbeat)
          .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)
      end

      it 'not interrupted, raise flag false' do
        response = subject.heartbeat
        expect(response.cancel_requested).to be(true)

        expect(client)
          .to have_received(:record_activity_task_heartbeat)
          .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)
      end
    end

    describe 'shutting down' do
      let(:is_shutting_down_proc) { proc { true } }

      it 'interrupted, raise flag true' do
        expect do
          subject.heartbeat(raise_when_interrupted: true)
        end.to raise_error(Temporal::ActivityWorkerShuttingDown)

        expect(client)
          .to have_received(:record_activity_task_heartbeat)
          .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)
      end

      it 'not interrupted, raise flag false' do
        subject.heartbeat

        expect(client)
          .to have_received(:record_activity_task_heartbeat)
          .with(namespace: metadata.namespace, task_token: metadata.task_token, details: nil)
      end
    end
  end

  describe '#heartbeat_details' do
    let(:metadata_hash) { Fabricate(:activity_metadata, heartbeat_details: 4).to_h }

    it 'returns the most recent heartbeat details' do
      expect(subject.heartbeat_details).to eq 4
    end
  end

  describe '#async!' do
    it 'marks activity context as async' do
      expect { subject.async }.to change { subject.async? }.from(false).to(true)
    end
  end

  describe '#async?' do
    subject { context.async? }
    let(:context) { described_class.new(client, metadata, nil, nil, nil) }

    context 'when context is sync' do
      it { is_expected.to eq(false) }
    end

    context 'when context is async' do
      before { context.async }

      it { is_expected.to eq(true) }
    end
  end

  describe '#async_token' do
    it 'returns async token' do
      expect(subject.async_token)
        .to eq(
          Temporal::Activity::AsyncToken.encode(
            metadata.namespace,
            metadata.id,
            metadata.workflow_id,
            metadata.workflow_run_id
          )
        )
    end
  end

  describe '#logger' do
    let(:logger) { instance_double('Logger') }

    before { allow(Temporal).to receive(:logger).and_return(logger) }

    it 'returns Temporal logger' do
      expect(subject.logger).to eq(logger)
    end
  end

  describe '#run_idem' do
    let(:metadata_hash) { Fabricate(:activity_metadata, id: '123', workflow_run_id: '123').to_h }
    let(:expected_uuid) { '601f1889-667e-5aeb-b33b-8c12572835da' }

    it 'returns idempotency token' do
      expect(subject.run_idem).to eq(expected_uuid)
    end
  end

  describe '#workflow_idem' do
    let(:metadata_hash) { Fabricate(:activity_metadata, id: '123', workflow_id: '123').to_h }
    let(:expected_uuid) { '601f1889-667e-5aeb-b33b-8c12572835da' }

    it 'returns idempotency token' do
      expect(subject.workflow_idem).to eq(expected_uuid)
    end
  end

  describe '#headers' do
    let(:metadata_hash) { Fabricate(:activity_metadata, headers: { 'Foo' => 'Bar' }).to_h }

    it 'returns headers' do
      expect(subject.headers).to eq('Foo' => 'Bar')
    end
  end

  describe '#name' do
    it 'returns the class name of the activity' do
      expect(subject.name).to eq('TestActivity')
    end
  end

  describe '#timed_out?' do
    let(:metadata_hash) { Fabricate(:activity_metadata, start_to_close_timeout: 0.1).to_h }

    it 'becomes true when start to close exceeded' do
      # Starts out as false
      expect(subject.timed_out?).to be(false)
      sleep 0.1
      expect(subject.timed_out?).to be(true)
    end
  end

  describe '#shutting_down?' do
    context 'is not shutting down' do
      it 'false' do
        expect(subject.shutting_down?).to be(false)
      end
    end

    context 'is shutting down' do
      let(:is_shutting_down_proc) { proc { true } }

      it 'true' do
        expect(subject.shutting_down?).to be(true)
      end
    end
  end
end
