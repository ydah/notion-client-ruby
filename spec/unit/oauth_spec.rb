# frozen_string_literal: true

RSpec.describe Notion::OAuth::Client do
  it "builds the authorization URL" do
    client = described_class.new(client_id: "client", client_secret: "secret", redirect_uri: "https://app.test/callback")

    uri = URI(client.authorize_url(state: "csrf"))
    query = URI.decode_www_form(uri.query).to_h

    expect(uri.path).to eq("/v1/oauth/authorize")
    expect(query).to include("client_id" => "client", "state" => "csrf", "owner" => "user")
  end

  it "exchanges, refreshes, introspects, and revokes tokens" do
    token_body = {
      access_token: "access",
      refresh_token: "refresh",
      bot_id: "bot",
      workspace_id: "workspace",
      expires_in: 3600
    }
    stub_request(:post, "https://api.notion.com/v1/oauth/token").to_return(status: 200, body: JSON.generate(token_body))
    stub_request(:post, "https://api.notion.com/v1/oauth/introspect").to_return(status: 200, body: '{"active":true}')
    stub_request(:post, "https://api.notion.com/v1/oauth/revoke").to_return(status: 200, body: "{}")
    client = described_class.new(client_id: "client", client_secret: "secret", redirect_uri: "https://app.test/callback")

    expect(client.exchange(code: "code").access_token).to eq("access")
    expect(client.refresh(refresh_token: "refresh").refresh_token).to eq("refresh")
    expect(client.introspect(token: "access")).to eq("active" => true)
    expect(client.revoke(token: "access")).to eq({})
    expect(a_request(:post, %r{/v1/oauth/}).with(headers: { "Authorization" => /^Basic / })).to have_been_made.times(4)
  end

  it "raises on OAuth API errors" do
    stub_request(:post, "https://api.notion.com/v1/oauth/introspect")
      .to_return(status: 401, body: '{"message":"invalid token"}')
    client = described_class.new(client_id: "client", client_secret: "secret", redirect_uri: "https://app.test/callback")

    expect { client.introspect(token: "bad") }.to raise_error(Notion::Error, "invalid token")
  end
end
