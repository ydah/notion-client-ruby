# frozen_string_literal: true

require "json"
require_relative "transport"

module Notion
  module Testing
    module_function

    def page(id: "page", properties: {}, **attributes)
      { "object" => "page", "id" => id, "properties" => properties }.merge(attributes.transform_keys(&:to_s))
    end

    def response(body, status: 200, headers: {})
      Transport::Response.new(
        status: status, headers: headers, body: JSON.generate(body), request_id: headers["x-request-id"], elapsed: 0
      )
    end

    def stub_notion_page(id: "page", **attributes)
      raise LoadError, "webmock is required for stub_notion_page" unless defined?(WebMock)

      WebMock.stub_request(:get, %r{/v1/pages/#{Regexp.escape(id)}\z})
             .to_return(status: 200, body: JSON.generate(page(id: id, **attributes)))
    end

    class Adapter < Transport::Adapter
      attr_reader :requests

      def initialize(*responses)
        super()
        @responses = responses
        @requests = []
      end

      def call(request)
        @requests << request
        response = @responses.shift || raise("no stubbed Notion response")
        return response if response.is_a?(Transport::Response)

        Transport::Response.new(status: 200, headers: {}, body: JSON.generate(response), request_id: nil, elapsed: 0)
      end
    end
  end
end
