# frozen_string_literal: true

RSpec.describe Notion::APIError do
  it "falls back to APIError for unknown codes while preserving details" do
    response = Notion::Transport::Response.new(
      status: 418,
      headers: { "retry-after" => "3" },
      body: { "code" => "new_error", "message" => "future", "additional_data" => { "x" => true } },
      request_id: "req_123",
      elapsed: 0
    )

    error = described_class.from_response(response)

    expect(error.class).to eq(described_class)
    expect(error.code).to eq("new_error")
    expect(error.request_id).to eq("req_123")
    expect(error.additional_data).to eq("x" => true)
    expect(error.retry_after).to eq(3.0)
  end
end
