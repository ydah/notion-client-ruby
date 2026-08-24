# frozen_string_literal: true

RSpec.describe Notion::Testing do
  it "builds page fixtures and transport responses" do
    page = described_class.page(id: "id", properties: { "Name" => {} }, future: true)
    response = described_class.response(page, headers: { "x-request-id" => "request" })

    expect(page).to include("object" => "page", "id" => "id", "future" => true)
    expect(response.request_id).to eq("request")
    expect(JSON.parse(response.body)).to eq(page)
  end

  it "stubs page retrieval when WebMock is available" do
    described_class.stub_notion_page(id: "page", properties: { "Name" => {} })

    response = Net::HTTP.get_response(URI("https://api.notion.com/v1/pages/page"))

    expect(response.code).to eq("200")
    expect(JSON.parse(response.body)).to include("object" => "page", "id" => "page")
  end
end
