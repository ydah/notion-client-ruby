# frozen_string_literal: true

RSpec.describe Notion::Generated::Endpoints::Pages do
  let(:client) do
    Class.new do
      attr_reader :last_request

      def request(*args, **kwargs)
        @last_request = [args, kwargs]
        { "object" => "page" }
      end
    end.new
  end
  let(:pages) { described_class.new(client) }

  it "places path and query parameters correctly" do
    result = pages.retrieve(page_id: "a/b", filter_properties: ["title"])

    expect(result).to eq("object" => "page")
    expect(client.last_request).to eq(
      [[:get, "/v1/pages/a%2Fb"], { query: { filter_properties: ["title"] }, body: nil }]
    )
  end

  it "puts remaining parameters in the JSON body" do
    pages.create(parent: { page_id: "parent" }, properties: {})

    expect(client.last_request.last.fetch(:body)).to eq(parent: { page_id: "parent" }, properties: {})
  end
end

RSpec.describe Notion::Endpoints::Base do
  it "validates required bodies and path values" do
    adapter = Notion::Testing::Adapter.new("object" => "page")
    client = Notion::Client.new(token: "token", adapter: adapter)

    expect { client.databases.create }.to raise_error(ArgumentError, /parent/)
    expect { client.pages.retrieve(page_id: nil) }.to raise_error(ArgumentError, /path parameter/)
  end

  it "validates required and enumerated query parameters" do
    client = Notion::Client.new(token: "token", adapter: Notion::Testing::Adapter.new)

    expect { client.comments.list }.to raise_error(ArgumentError, /block_id/)
    expect { client.file_uploads.list(status: :unknown) }.to raise_error(ArgumentError, /status/)
    expect { client.file_uploads.create(mode: :unknown) }.to raise_error(ArgumentError, /mode/)
    expect { client.meeting_notes.create(source: {}, title: "x" * 2001) }.to raise_error(ArgumentError, /title/)
  end

  it "validates alternative request body contracts" do
    adapter = Notion::Testing::Adapter.new("object" => "comment")
    client = Notion::Client.new(token: "token", adapter: adapter)

    expect { client.comments.create }.to raise_error(ArgumentError, /parent \+ rich_text/)
    expect { client.comments.create(discussion_id: "id", markdown: "hello") }.not_to raise_error
  end

  it "sends an empty object when every body field is optional" do
    adapter = Notion::Testing::Adapter.new("object" => "list", "results" => [], "has_more" => false)
    client = Notion::Client.new(token: "token", adapter: adapter)

    client.send(:endpoint, :search).search

    expect(adapter.requests.last.body).to eq("{}")
  end

  it "accepts a query block on generated operations" do
    adapter = Notion::Testing::Adapter.new("object" => "list", "results" => [], "has_more" => false)
    client = Notion::Client.new(token: "token", adapter: adapter)

    client.send(:endpoint, :search).search { |query| query.raw(property: "object", value: "page") }

    expect(JSON.parse(adapter.requests.last.body)).to include("filter" => { "property" => "object", "value" => "page" })
  end

  it "sends the generated upload operation as multipart data" do
    adapter = Notion::Testing::Adapter.new("object" => "file_upload")
    client = Notion::Client.new(token: "token", adapter: adapter)

    client.file_uploads.send(file_upload_id: "id", data: "data", filename: "x.txt", content_type: "text/plain")

    expect(adapter.requests.last.headers.fetch("content-type")).to start_with("multipart/form-data; boundary=")
  end
end
