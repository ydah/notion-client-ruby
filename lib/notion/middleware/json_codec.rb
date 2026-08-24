# frozen_string_literal: true

require "json"

module Notion
  module Middleware
    class JsonCodec
      def initialize(app)
        @app = app
      end

      def call(request)
        response = @app.call(encode(request))
        response.with(body: decode(response))
      end

      private

      def encode(request)
        return request unless request.body.is_a?(Hash) || request.body.is_a?(Array)

        request.with(
          body: JSON.generate(request.body),
          headers: request.headers.merge("content-type" => "application/json")
        )
      end

      def decode(response)
        return nil if response.body.nil? || response.body.empty?

        JSON.parse(response.body)
      rescue JSON::ParserError
        response.body
      end
    end
  end
end
