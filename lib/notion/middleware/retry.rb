# frozen_string_literal: true

module Notion
  module Middleware
    class Retry
      RETRYABLE = [429, 529].freeze
      IDEMPOTENT_RETRYABLE = [500, 502, 503, 504].freeze

      def initialize(app, max_attempts:, cap:, sleeper: Kernel.method(:sleep), random: Random.new)
        @app = app
        @max_attempts = max_attempts
        @cap = cap
        @sleeper = sleeper
        @random = random
      end

      def call(request)
        attempt = 0
        loop do
          attempt += 1
          response = @app.call(request)
          unless attempt < @max_attempts && retryable?(response, request)
            return response.with(attempt: attempt, retried: attempt > 1)
          end

          @sleeper.call(delay(response, attempt))
        end
      end

      private

      def retryable?(response, request)
        RETRYABLE.include?(response.status) ||
          (request.idempotent? && IDEMPOTENT_RETRYABLE.include?(response.status))
      end

      def delay(response, attempt)
        retry_after = response.headers["retry-after"]
        return retry_after.to_f if retry_after

        @random.rand * [2**(attempt - 1), @cap].min
      end
    end
  end
end
