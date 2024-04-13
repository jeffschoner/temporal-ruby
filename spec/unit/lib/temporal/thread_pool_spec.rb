require 'temporal/thread_pool'

describe Temporal::ThreadPool do
  before do
    allow(Temporal.metrics).to receive(:gauge)
  end

  let(:config) { Temporal::Configuration.new }
  let(:size) { 2 }
  let(:tags) { { foo: 'bar', bat: 'baz' } }
  let(:thread_pool) { described_class.new(size, config, tags) }

  it 'executes one task with zero delay on a thread and exits' do
    times = 0

    thread_pool.schedule(0) do
      times += 1
    end

    thread_pool.shutdown

    expect(times).to eq(1)
  end

  it 'executes tasks with delays in time order' do
    answers = Queue.new
    mutex = Mutex.new
    cv = ConditionVariable.new

    thread_pool.schedule(0.2) do
      answers << :second
      cv.signal
    end

    thread_pool.schedule(0.1) do
      answers << :first
      cv.signal
    end

    # Wait for both to run before shutting down
    mutex.synchronize do
      cv.wait(mutex)
      cv.wait(mutex)
    end

    thread_pool.shutdown

    expect(answers.size).to eq(2)
    expect(answers.pop).to eq(:first)
    expect(answers.pop).to eq(:second)
  end

  describe '#cancel' do
    it 'cancels already waiting task' do
      answers = Queue.new
      handles = []

      handles << thread_pool.schedule(30) do
        answers << :foo
      end

      handles << thread_pool.schedule(30) do
        answers << :bar
      end

      # Even though this has no wait, it will be blocked by the above
      # two long running tasks until one is finished or cancels.
      handles << thread_pool.schedule(0) do
        answers << :baz
      end

      # Canceling one waiting item (foo) will let a blocked one (baz) through
      handles[0].cancel

      # Canceling the other waiting item (bar) will prevent it from blocking
      # on shutdown
      handles[1].cancel

      thread_pool.shutdown

      expect(answers.size).to eq(1)
      expect(answers.pop).to eq(:baz)
    end

    it 'cancels blocked task' do
      times = 0
      handles = []

      handles << thread_pool.schedule(30) do
        times += 1
      end

      handles << thread_pool.schedule(30) do
        times += 1
      end

      # Even though this has no wait, it will be blocked by the above
      # two long running tasks. This test ensures it can be canceled
      # even while waiting to run.
      handles << thread_pool.schedule(0) do
        times += 1
      end

      # Cancel this one before it can start running
      handles[0].cancel

      # Cancel the others so that they don't block shutdown
      handles[1].cancel
      handles[2].cancel

      thread_pool.shutdown

      expect(times).to eq(0)
    end

    it 'cannot cancel uncancellable item' do
      handle = thread_pool.schedule(30, cancelable: false) do; end

      expect do
        handle.cancel
      end.to raise_error(Temporal::ClientError)

      thread_pool.shutdown
    end

    # TODO: Plumb this through activity heartbeating
    it 'tasks can opt into worker shutdown interruption' do
      times = 0
      shutting_down = false

      thread_pool.schedule do
        times += 1
        begin
          Thread.handle_interrupt(Temporal::WorkerShuttingDownError => :immediate) do
            loop do
              sleep 0.1
            end
          end
        rescue Temporal::WorkerShuttingDownError
          shutting_down = true
          raise
        end
      end

      thread_pool.shutdown

      expect(times).to eq(1)
      expect(shutting_down).to eq(true)
    end
  end
end
