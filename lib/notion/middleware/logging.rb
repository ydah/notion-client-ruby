# frozen_string_literal: true

require "json"

module Notion
  module Middleware
    class Logging
      SENSITIVE = /authorization|token|secret/i

      def initialize(app, logger:, level: :info)
        @app = app
        @logger = logger
        @level = level
      end

      def call(request)
        return @app.call(request) unless @logger

        log(event: "request", method: request.verb, path: request.path, headers: redact(request.headers))
        response = @app.call(request)
        log(event: "response", status: response.status, request_id: response.request_id)
        response
      end

      private

      def redact(value)
        value.to_h { |key, item| [key, key.to_s.match?(SENSITIVE) ? "[REDACTED]" : item] }
      end

      def log(payload)
        @logger.public_send(@level, JSON.generate(payload))
      end
    end
  end
end
