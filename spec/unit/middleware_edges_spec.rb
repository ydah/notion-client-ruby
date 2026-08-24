# frozen_string_literal: true

RSpec.describe "middleware edge behavior" do
  let(:request) do
    Notion::Transport::Request.new(
      verb: :get, path: "/v1/test", query: {}, headers: {}, body: nil, idempotent: true
    )
  end

  it "requires a token and uses a stored unexpired token" do
    config = Notion::Config.new
    config.token = nil
    middleware = Notion::Middleware::Authentication.new(->(value) { value }, config)
    expect { middleware.call(request) }.to raise_error(Notion::ConfigurationError, /token/)

    token = Notion::OAuth::Token.new(
      access_token: "stored", refresh_token: nil, bot_id: nil, workspace_id: nil,
      expires_at: Time.now + 60, raw: {}
    )
    config.token_store = Notion::OAuth::MemoryTokenStore.new
    config.token_store.write(:default, token)
    expect(middleware.call(request).headers["authorization"]).to eq("Bearer stored")
  end

  it "validates automatic refresh dependencies" do
    token = Notion::OAuth::Token.new(
      access_token: "old", refresh_token: nil, bot_id: nil, workspace_id: nil,
      expires_at: Time.now - 1, raw: {}
    )
    config = Notion::Config.new
    config.token_store = Notion::OAuth::MemoryTokenStore.new
    config.token_store.write(:default, token)
    config.auto_refresh = true
    middleware = Notion::Middleware::Authentication.new(->(value) { value }, config)

    expect { middleware.call(request) }.to raise_error(Notion::ConfigurationError, /oauth_client/)
    config.oauth_client = Object.new
    expect { middleware.call(request) }.to raise_error(Notion::ConfigurationError, /refresh token/)
  end

  it "adds beta versions and handles plain response bodies" do
    config = Notion::Config.new
    config.betas = ["beta"]
    response = Notion::Transport::Response.new(
      status: 204, headers: {}, body: "", request_id: nil, elapsed: 0
    )
    captured = nil
    app = lambda do |value|
      captured = value
      response
    end
    codec = Notion::Middleware::JsonCodec.new(app)
    versioned = Notion::Middleware::ApiVersion.new(codec, config)
    result = versioned.call(request.with(body: "plain"))

    expect(result.body).to be_nil
    expect(captured.headers["notion-beta"]).to eq("beta")
  end

  it "publishes to ActiveSupport when present" do
    notifications = Class.new do
      class << self
        attr_reader :event

        def instrument(*event)
          @event = event
        end
      end
    end
    stub_const("ActiveSupport", Module.new)
    stub_const("ActiveSupport::Notifications", notifications)
    response = Notion::Transport::Response.new(
      status: 200, headers: {}, body: {}, request_id: nil, elapsed: 0
    )
    Notion::Middleware::Instrumentation.new(->(_value) { response }).call(request)

    expect(notifications.event.first).to eq("request.notion")
  end
end
