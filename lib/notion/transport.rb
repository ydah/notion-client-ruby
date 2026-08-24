# frozen_string_literal: true

module Notion
  module Transport
    Request = Data.define(:verb, :path, :query, :headers, :body, :idempotent) do
      def idempotent? = idempotent
    end

    Response = Data.define(:status, :headers, :body, :request_id, :elapsed, :attempt, :retried) do
      def initialize(status:, headers:, body:, request_id:, elapsed:, attempt: 1, retried: false)
        super
      end
    end

    class Adapter
      def call(_request)
        raise NotImplementedError
      end
    end
  end
end
