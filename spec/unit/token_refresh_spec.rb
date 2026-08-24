# frozen_string_literal: true

RSpec.describe "OAuth token refresh" do
  it "refreshes and stores an expired token before authentication" do
    expired = Notion::OAuth::Token.new(
      access_token: "old",
      refresh_token: "refresh",
      bot_id: nil,
      workspace_id: nil,
      expires_at: Time.now - 1,
      raw: {}
    )
    fresh = expired.with(access_token: "new", expires_at: Time.now + 3600)
    store = Notion::OAuth::MemoryTokenStore.new
    store.write(:workspace, expired)
    oauth = Object.new
    oauth.define_singleton_method(:refresh) { |refresh_token:| refresh_token == "refresh" ? fresh : raise }
    adapter = Notion::Testing::Adapter.new("object" => "user")
    client = Notion::Client.new(
      adapter: adapter,
      token_store: store,
      token_key: :workspace,
      oauth_client: oauth,
      auto_refresh: true
    )

    client.users.me

    expect(adapter.requests.first.headers["authorization"]).to eq("Bearer new")
    expect(store.read(:workspace)).to eq(fresh)
  end
end
