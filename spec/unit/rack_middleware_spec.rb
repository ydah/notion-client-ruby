# frozen_string_literal: true

require "stringio"

RSpec.describe Notion::Webhooks::RackMiddleware do
  let(:fallback) { ->(_env) { [404, {}, []] } }

  it "accepts the initial verification request without a signature" do
    events = []
    middleware = described_class.new(fallback, secret: "secret") { |event| events << event }
    status, = middleware.call(
      "PATH_INFO" => "/notion/events",
      "REQUEST_METHOD" => "POST",
      "rack.input" => StringIO.new('{"verification_token":"verify_me"}')
    )

    expect(status).to eq(200)
    expect(events.first.verification_token).to eq("verify_me")
  end

  it "accepts an officially signed event" do
    payload = '{"type":"page.content_updated"}'
    signature = OpenSSL::HMAC.hexdigest("SHA256", "secret", payload)
    middleware = described_class.new(fallback, secret: "secret")

    status, = middleware.call(
      "PATH_INFO" => "/notion/events",
      "REQUEST_METHOD" => "POST",
      "HTTP_X_NOTION_SIGNATURE" => "sha256=#{signature}",
      "rack.input" => StringIO.new(payload)
    )

    expect(status).to eq(200)
  end

  it "passes other requests through and rejects malformed events" do
    middleware = described_class.new(fallback, secret: "secret")
    expect(middleware.call("PATH_INFO" => "/other", "REQUEST_METHOD" => "GET").first).to eq(404)

    invalid = { "PATH_INFO" => "/notion/events", "REQUEST_METHOD" => "POST", "rack.input" => StringIO.new("{") }
    unsigned = invalid.merge("rack.input" => StringIO.new('{"type":"event"}'))
    expect(middleware.call(invalid).first).to eq(400)
    expect(middleware.call(unsigned).first).to eq(401)
  end
end
