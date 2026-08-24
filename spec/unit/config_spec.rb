# frozen_string_literal: true

RSpec.describe Notion::Config do
  it "validates required, supported, positive, and known settings" do
    config = described_class.new
    config.token = nil
    expect { config.validate!(require_token: true) }.to raise_error(Notion::ConfigurationError, /token/)

    config.token_store = Object.new
    expect(config.validate!(require_token: true)).to equal(config)
    expect { config.merge(notion_version: "future") }.to raise_error(Notion::ConfigurationError, /unsupported/)
    expect { config.merge(rate: 0) }.to raise_error(Notion::ConfigurationError, /positive/)
    expect { config.merge(unknown: true) }.to raise_error(Notion::ConfigurationError, /unknown/)
  end

  it "accepts the documented grouped settings" do
    store = Object.new
    config = described_class.new
    config.timeout = { open: 2, read: 3 }
    config.retry = { max_attempts: 4, cap: 5 }
    config.rate_limit = { rate: 6, burst: 7, store: store }
    config.adapter = :net_http

    expect(config).to have_attributes(
      open_timeout: 2, read_timeout: 3, max_attempts: 4, retry_cap: 5,
      rate: 6, burst: 7, rate_limit_store: store, adapter: :net_http
    )
    expect { config.merge(retry_cap: 0) }.to raise_error(Notion::ConfigurationError, /positive/)
  end
end
