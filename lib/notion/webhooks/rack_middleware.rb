# frozen_string_literal: true

require "json"

module Notion
  module Webhooks
    class RackMiddleware
      def initialize(app, secret:, path: "/notion/events", &handler)
        @app = app
        @secret = secret
        @path = path
        @handler = handler
      end

      def call(env)
        return @app.call(env) unless env["PATH_INFO"] == @path && env["REQUEST_METHOD"] == "POST"

        payload = env.fetch("rack.input").read
        data = JSON.parse(payload)
        return verify_subscription(data) if data.key?("verification_token")

        valid = Signature.valid?(
          secret: @secret,
          payload: payload,
          signature: env["HTTP_X_NOTION_SIGNATURE"] || env["HTTP_NOTION_SIGNATURE"]
        )
        return [401, { "content-type" => "text/plain" }, ["invalid signature"]] unless valid

        @handler&.call(Event.new(data))
        [200, {}, []]
      rescue JSON::ParserError
        [400, { "content-type" => "text/plain" }, ["invalid JSON"]]
      end

      private

      def verify_subscription(data)
        @handler&.call(Event.new(data))
        [200, { "content-type" => "application/json" }, [JSON.generate(data)]]
      end
    end
  end
end
