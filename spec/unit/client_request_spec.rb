# frozen_string_literal: true

RSpec.describe Notion::Client do
  let(:adapter) do
    Class.new(Notion::Transport::Adapter) do
      attr_reader :requests

      def initialize(response)
        super()
        @response = response
        @requests = []
      end

      def call(request)
        @requests << request
        @response
      end
    end.new(response)
  end
  let(:response) do
    Notion::Transport::Response.new(
      status: 200, headers: {}, body: '{"object":"user"}', request_id: "req", elapsed: 0.1
    )
  end

  it "sends authenticated, versioned JSON requests" do
    client = described_class.new(token: "ntn_secret", adapter: adapter, rate: 1000)

    result = client.request(:post, "/v1/pages", body: { parent: { page_id: "id" } })

    expect(result).to be_a(Notion::Objects::User)
    expect(result.raw).to eq("object" => "user")
    expect(adapter.requests.one?).to be(true)
    expect(adapter.requests.first.headers).to include(
      "authorization" => "Bearer ntn_secret",
      "notion-version" => "2026-03-11",
      "content-type" => "application/json"
    )
    expect(adapter.requests.first.body).to eq('{"parent":{"page_id":"id"}}')
  end

  it "raises a mapped API error" do
    error_response = response.with(status: 404, body: '{"code":"object_not_found","message":"missing"}')
    client = described_class.new(token: "secret", adapter: adapter.class.new(error_response))

    expect { client.request(:get, "/v1/pages/missing") }
      .to raise_error(Notion::ObjectNotFoundError, "missing")
  end

  it "does not expose the token in inspect" do
    client = described_class.new(token: "ntn_secret", adapter: adapter)

    expect(client.inspect).not_to include("ntn_secret")
  end

  it "validates paths and respects explicit idempotency" do
    client = described_class.new(token: "token", adapter: adapter)

    expect { client.request(:get, "v1/users/me") }.to raise_error(ArgumentError, /start with/)
    client.request(:post, "/v1/test", query: { keep: 1, drop: nil }, idempotent: true)
    sent = adapter.requests.last
    expect(sent.query).to eq(keep: 1)
    expect(sent.idempotent).to be(true)
  end
end
