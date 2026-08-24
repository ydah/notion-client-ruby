# frozen_string_literal: true

require "stringio"

RSpec.describe Notion::Middleware::Logging do
  it "redacts authorization headers" do
    output = StringIO.new
    logger = Object.new
    logger.define_singleton_method(:info) { |message| output << message }
    response = Notion::Transport::Response.new(status: 200, headers: {}, body: {}, request_id: nil, elapsed: 0)
    middleware = described_class.new(->(_request) { response }, logger: logger)
    request = Notion::Transport::Request.new(
      verb: :get,
      path: "/v1/users/me",
      query: {},
      headers: { "authorization" => "Bearer ntn_secret" },
      body: nil,
      idempotent: true
    )

    middleware.call(request)

    expect(output.string).to include("[REDACTED]")
    expect(output.string).not_to include("ntn_secret")
  end
end
