# frozen_string_literal: true

RSpec.describe Notion::Middleware::Instrumentation do
  it "publishes request metadata and supports unsubscribe" do
    events = []
    subscriber = described_class.subscribe { |name, payload| events << [name, payload] }
    response = Notion::Transport::Response.new(status: 200, headers: {}, body: {}, request_id: "req", elapsed: 0)
    middleware = described_class.new(->(_request) { response })
    request = Notion::Transport::Request.new(
      verb: :get, path: "/v1/users/me", query: {}, headers: {}, body: nil, idempotent: true
    )

    middleware.call(request)
    described_class.unsubscribe(subscriber)

    expect(events.first.first).to eq("request.notion")
    expect(events.first.last).to include(status: 200, request_id: "req", attempt: 1, retried: false)
  end
end
