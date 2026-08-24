# frozen_string_literal: true

RSpec.describe Notion::Middleware::Retry do
  let(:request) do
    Notion::Transport::Request.new(verb: :get, path: "/", query: {}, headers: {}, body: nil, idempotent: true)
  end

  it "honors Retry-After for rate limits" do
    responses = [response(429, "retry-after" => "2"), response(200)]
    app = ->(_request) { responses.shift }
    waits = []
    middleware = described_class.new(app, max_attempts: 2, cap: 30, sleeper: ->(seconds) { waits << seconds })

    result = middleware.call(request)

    expect(result.status).to eq(200)
    expect(result).to have_attributes(attempt: 2, retried: true)
    expect(waits).to eq([2.0])
  end

  it "does not retry server errors for non-idempotent requests" do
    calls = 0
    app = lambda do |_request|
      calls += 1
      response(500)
    end
    middleware = described_class.new(app, max_attempts: 5, cap: 30)

    middleware.call(request.with(idempotent: false))

    expect(calls).to eq(1)
  end

  it "retries idempotent server errors with full jitter" do
    responses = [response(500), response(200)]
    waits = []
    random = Object.new
    random.define_singleton_method(:rand) { 0.5 }
    middleware = described_class.new(
      ->(_request) { responses.shift }, max_attempts: 2, cap: 30,
                                        sleeper: ->(seconds) { waits << seconds }, random: random
    )

    expect(middleware.call(request).status).to eq(200)
    expect(waits).to eq([0.5])
  end

  it "always retries service overload responses" do
    responses = [response(529), response(200)]
    middleware = described_class.new(
      ->(_request) { responses.shift }, max_attempts: 2, cap: 30, sleeper: ->(_seconds) {}
    )

    expect(middleware.call(request.with(idempotent: false)).status).to eq(200)
  end

  def response(status, headers = {})
    Notion::Transport::Response.new(status: status, headers: headers, body: {}, request_id: nil, elapsed: 0)
  end
end
