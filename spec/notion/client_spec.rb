# frozen_string_literal: true

RSpec.describe Notion::Client do
  it "has a version number" do
    expect(Notion::VERSION).not_to be_nil
  end

  it "uses global configuration without sharing client mutations" do
    Notion.configure { |config| config.token = "secret" }

    client = described_class.new(read_timeout: 10)

    expect(client.config.token).to eq("secret")
    expect(client.config.read_timeout).to eq(10)
    expect(Notion.configuration.read_timeout).to eq(65)
    expect(client.config).to be_frozen
  end

  it "freezes nested configuration and shares endpoint instances across threads" do
    adapter = Notion::Testing::Adapter.new
    client = described_class.new(token: "token", adapter: adapter)
    endpoints = Array.new(8) { Thread.new { client.pages } }.map(&:value)

    expect(client.config.betas).to be_frozen
    expect(endpoints.uniq.length).to eq(1)
  end

  it "accepts the documented net_http adapter symbol" do
    client = described_class.new(token: "token", adapter: :net_http, base_url: "http://127.0.0.1")

    expect(client.config.adapter).to eq(:net_http)
  end
end
