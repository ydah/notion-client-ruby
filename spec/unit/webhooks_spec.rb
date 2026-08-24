# frozen_string_literal: true

require "openssl"

RSpec.describe Notion::Webhooks::Signature do
  it "verifies the official raw-body HMAC signature" do
    payload = '{"type":"page.updated"}'
    signature = OpenSSL::HMAC.hexdigest("SHA256", "secret", payload)

    expect(
      described_class.valid?(
        secret: "secret",
        payload: payload,
        signature: "sha256=#{signature}"
      )
    ).to be(true)
    expect(
      described_class.valid?(
        secret: "secret",
        payload: "tampered",
        signature: signature
      )
    ).to be(false)
  end
end
