require 'temporal/errors'

class LongRunningActivity < Temporal::Activity
  class Canceled < Temporal::ActivityException; end

  def execute(cycles, interval, on_cancel)
    cycles.times do
      # Cancellation is only detected through heartbeating, but your activity code may not
      # be immediately informed because of throttling which sends the heartbeat on a background
      # thread. Once cancellation has been triggered, there are three ways to know about it,
      # illustrated below.

      # 1. Check the cancel_requested bit on the activity context. This is not the preferred
      # method, but it's preserved for backward compatibility in older versions of temporal-ruby.
      activity.logger.info("activity.cancel_requested: #{activity.cancel_requested}")

      # 2. When heartbeating, an ActivityCanceled error will be raised. If this error is not
      # rescued or if it is rethrown, Temporal server will move the activity's state into 
      # canceled. This in turn will result in an ActivityCanceled result being raised into
      # any workflow code that attempts to get the result of this activity.
      begin
        activity.heartbeat
      rescue Temporal::ActivityCanceled
        case on_cancel
        when "fail"
          # This will fail the activity because a different type is causing it to exit
          raise Canceled, 'cancel activity request received'
        when "cancel"
          # Re-raising or letting the ActivityCanceled through will result in the activity entering
          # a canceled state
          raise
        when "ignore"
          # Cancellation can be ignored entirely. If the activity completes or fails later, it will
          # end up in a successful or failed state respectively.
        end
      rescue Temporal::WorkerShuttingDownError
        # This error is similar to cancellation, but is raised on heartbeating when
        # the worker is currently shutting down.
        raise
      end

      # 3. You can opt any code to being interrupted by cancellation at any point through
      # a Thread.handle_interrupt call. You can handle ActivityCanceled, WorkerShuttingDownError
      # or ActivityInterruptedError which is the superclass of them both.
      Thread.handle_interrupt(Temporal::ActivityInterruptedError => :immediate) do
        sleep interval
      end
    end

    return
  end
end
