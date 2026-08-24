# frozen_string_literal: true

module Notion
  module Middleware
    class Instrumentation
      @subscribers = []
      @mutex = Mutex.new

      class << self
        attr_reader :subscribers

        def subscribe(&block)
          @mutex.synchronize { subscribers << block }
          block
        end

        def unsubscribe(block)
          @mutex.synchronize { subscribers.delete(block) }
        end

        def each_subscriber(&)
          @mutex.synchronize { subscribers.dup }.each(&)
        end

        def publish(name, payload)
          each_subscriber { |subscriber| subscriber.call(name, payload) }
          ActiveSupport::Notifications.instrument(name, payload) if defined?(ActiveSupport::Notifications)
        end
      end

      def initialize(app, clock: Process.method(:clock_gettime))
        @app = app
        @clock = clock
      end

      def call(request)
        started = monotonic
        response = @app.call(request)
        publish(request, response, monotonic - started)
        response
      end

      private

      def publish(request, response, duration)
        payload = {
          method: request.verb,
          path: request.path,
          status: response.status,
          duration: duration,
          request_id: response.request_id,
          attempt: response.attempt,
          retried: response.retried
        }
        self.class.publish("request.notion", payload)
      end

      def monotonic
        @clock.call(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
