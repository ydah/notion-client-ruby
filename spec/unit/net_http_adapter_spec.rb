# frozen_string_literal: true

RSpec.describe Notion::Transport::NetHTTPAdapter do
  it "sends requests through Net::HTTP" do
    stub_request(:get, "https://api.notion.com/v1/users/me?verbose=true")
      .to_return(status: 200, body: '{"object":"user"}', headers: { "X-Request-Id" => "req" })
    config = Notion::Config.new
    adapter = described_class.new(config, pool_size: 1)
    request = Notion::Transport::Request.new(
      verb: :get,
      path: "/v1/users/me",
      query: { verbose: true },
      headers: {},
      body: nil,
      idempotent: true
    )

    response = adapter.call(request)

    expect(response.status).to eq(200)
    expect(response.request_id).to eq("req")
    expect(a_request(:get, "https://api.notion.com/v1/users/me?verbose=true")).to have_been_made.once
  end

  it "builds proxy, TLS, body, and empty-query request variants" do
    config = Notion::Config.new
    config.proxy = "http://user:pass@proxy.test:8080"
    config.ca_file = "/tmp/ca.pem"
    adapter = described_class.new(config, pool_size: 1)
    connection = adapter.send(:build_connection)
    request = Notion::Transport::Request.new(
      verb: :post, path: "/v1/test", query: {}, headers: {}, body: "body", idempotent: false
    )
    built = adapter.send(:build_request, request)

    expect(connection.ca_file).to eq("/tmp/ca.pem")
    expect(built.body).to eq("body")
    expect(built.uri.query).to be_nil
    expect { adapter.send(:build_request, request.with(verb: :trace)) }.to raise_error(ArgumentError, /unsupported/)
  end

  it "maps timeouts and replaces broken connections" do
    http = Class.new do
      def started? = @started
      def start = @started = true
      def request(*) = raise(Timeout::Error, "slow")
      def finish = @started = false
    end.new
    adapter = described_class.new(Notion::Config.new, pool_size: 1)
    pool = adapter.instance_variable_get(:@pool)
    pool.pop
    pool << http
    request = Notion::Transport::Request.new(
      verb: :get, path: "/v1/test", query: {}, headers: {}, body: nil, idempotent: true
    )

    expect { adapter.call(request) }.to raise_error(Notion::TimeoutError, "slow")
    expect(pool.length).to eq(1)
  end
end
