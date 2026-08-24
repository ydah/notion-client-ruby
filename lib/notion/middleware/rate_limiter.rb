# frozen_string_literal: true

module Notion
  module Middleware
    class RateLimiter
      State = Struct.new(:tokens, :updated_at, :blocked_until, :mutex)

      class MemoryStore
        def initialize
          @states = {}
          @mutex = Mutex.new
        end

        def state(key, burst, now)
          return State.new(burst, now, now, Mutex.new) unless key

          @mutex.synchronize { @states[key] ||= State.new(burst, now, now, Mutex.new) }
        end
      end

      DEFAULT_STORE = MemoryStore.new

      def initialize(
        app, rate:, burst:, key: nil, store: DEFAULT_STORE,
        clock: Process.method(:clock_gettime), sleeper: Kernel.method(:sleep)
      )
        @app = app
        @rate = rate.to_f
        @burst = burst.to_f
        @clock = clock
        @sleeper = sleeper
        @state = store.state(key && [key, @rate, @burst], @burst, monotonic)
      end

      def call(request)
        wait
        response = @app.call(request)
        pause(response.headers["retry-after"].to_f, response) if response.status == 429
        response
      end

      private

      def wait
        loop do
          delay = @state.mutex.synchronize { next_delay }
          return unless delay.positive?

          @sleeper.call(delay)
        end
      end

      def next_delay
        now = monotonic
        return @state.blocked_until - now if now < @state.blocked_until

        @state.tokens = [@burst, @state.tokens + ((now - @state.updated_at) * @rate)].min
        @state.updated_at = now
        return (1.0 - @state.tokens) / @rate if @state.tokens < 1.0

        @state.tokens -= 1.0
        0
      end

      def pause(seconds, response)
        @state.mutex.synchronize do
          @state.blocked_until = [@state.blocked_until, monotonic + seconds].max
        end
        reason = response.body&.dig("additional_data", "rate_limit_reason") if response.body.is_a?(Hash)
        Instrumentation.publish("rate_limited.notion", retry_after: seconds, reason: reason)
      end

      def monotonic
        @clock.call(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
