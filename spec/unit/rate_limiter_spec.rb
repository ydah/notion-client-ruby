# frozen_string_literal: true

RSpec.describe Notion::Middleware::RateLimiter do
  let(:request) do
    Notion::Transport::Request.new(
      verb: :get, path: "/", query: {}, headers: {}, body: nil, idempotent: true
    )
  end

  it "shares a bucket between clients using the same token" do
    now = 0.0
    waits = []
    clock = ->(_clock_id) { now }
    sleeper = lambda do |delay|
      waits << delay
      now += delay
    end
    response = Notion::Transport::Response.new(status: 200, headers: {}, body: {}, request_id: nil, elapsed: 0)
    options = { rate: 1, burst: 1, key: "shared", clock: clock, sleeper: sleeper }
    first = described_class.new(->(_request) { response }, **options)
    second = described_class.new(->(_request) { response }, **options)

    first.call(request)
    second.call(request)

    expect(waits).to eq([1.0])
  end

  it "pauses the bucket and publishes the rate-limit reason" do
    now = 0.0
    waits = []
    events = []
    subscriber = Notion::Middleware::Instrumentation.subscribe { |name, payload| events << [name, payload] }
    clock = ->(_clock_id) { now }
    sleeper = lambda do |delay|
      waits << delay
      now += delay
    end
    limited = Notion::Transport::Response.new(
      status: 429, headers: { "retry-after" => "2" },
      body: { "additional_data" => { "rate_limit_reason" => "workspace" } }, request_id: nil, elapsed: 0
    )
    ok = limited.with(status: 200, headers: {}, body: {})
    responses = [limited, ok]
    middleware = described_class.new(
      ->(_request) { responses.shift }, rate: 10, burst: 2, key: "limited",
                                        store: described_class::MemoryStore.new, clock: clock, sleeper: sleeper
    )
    middleware.call(request)
    middleware.call(request)

    expect(waits).to eq([2.0])
    expect(events).to include(["rate_limited.notion", { retry_after: 2.0, reason: "workspace" }])
  ensure
    Notion::Middleware::Instrumentation.unsubscribe(subscriber) if subscriber
  end
end
