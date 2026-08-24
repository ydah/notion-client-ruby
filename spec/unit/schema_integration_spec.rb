# frozen_string_literal: true

RSpec.describe "schema-aware endpoints" do
  it "caches schemas and converts primitive page updates" do
    adapter = Notion::Testing::Adapter.new(
      { "object" => "page", "id" => "page", "parent" => { "data_source_id" => "source" } },
      { "object" => "data_source", "id" => "source", "properties" => { "Done" => { "type" => "checkbox" } } },
      { "object" => "page", "id" => "page" }
    )
    client = Notion::Client.new(token: "secret", adapter: adapter, strict: true)

    client.pages.update(page_id: "page", properties: { "Done" => true })

    body = JSON.parse(adapter.requests.last.body)
    expect(body.dig("properties", "Done")).to eq("checkbox" => true)
    expect(client.schema_for("source")).to eq("Done" => { "type" => "checkbox" })
    expect(adapter.requests.count { |request| request.path == "/v1/data_sources/source" }).to eq(1)
  end

  it "uses a schema-aware query filter and sync timestamp" do
    adapter = Notion::Testing::Adapter.new(
      { "object" => "data_source", "properties" => { "Status" => { "type" => "status" } } },
      { "object" => "list", "results" => [], "has_more" => false, "next_cursor" => nil },
      { "object" => "list", "results" => [], "has_more" => false, "next_cursor" => nil }
    )
    client = Notion::Client.new(token: "secret", adapter: adapter, strict: true)

    client.data_sources.query(data_source_id: "source") { |query| query.where(:Status).equals("Done") }
    client.data_sources.sync_since(data_source_id: "source", time: Time.utc(2026, 8, 24))

    query_body = JSON.parse(adapter.requests[1].body)
    sync_body = JSON.parse(adapter.requests[2].body)
    expect(query_body.dig("filter", "status", "equals")).to eq("Done")
    expect(sync_body.dig("filter", "last_edited_time", "on_or_after")).to eq("2026-08-24T00:00:00Z")
  end

  it "resolves a database parent before creating a modern page" do
    adapter = Notion::Testing::Adapter.new(
      { "object" => "database", "data_sources" => [{ "id" => "source", "name" => "Tasks" }] },
      { "object" => "data_source", "properties" => { "Name" => { "type" => "title" } } },
      { "object" => "page", "id" => "page" }
    )
    client = Notion::Client.new(token: "token", adapter: adapter, rate: 1000)

    client.pages.create(parent: { database_id: "database" }, properties: { "Name" => "Task" })
    body = JSON.parse(adapter.requests.last.body)

    expect(body["parent"]).to eq("data_source_id" => "source")
    expect(body.dig("properties", "Name", "title", 0, "text", "content")).to eq("Task")
  end

  it "queries and creates pages through the legacy database API" do
    adapter = Notion::Testing::Adapter.new(
      { "object" => "list", "results" => [], "has_more" => false },
      { "object" => "database", "properties" => { "Name" => { "type" => "title" } } },
      { "object" => "page", "id" => "page" }
    )
    client = Notion::Client.new(
      token: "token", adapter: adapter, rate: 1000, notion_version: "2022-06-28"
    )

    client.query("database", filter: { property: "Name", title: { is_not_empty: true } })
    client.pages.create(parent: { database_id: "database" }, properties: { "Name" => "Task" })

    expect(adapter.requests.map(&:path)).to eq(
      ["/v1/databases/database/query", "/v1/databases/database", "/v1/pages"]
    )
    expect(JSON.parse(adapter.requests.last.body).dig("parent", "database_id")).to eq("database")
  end

  it "shares and invalidates schemas through an injected cache" do
    cache = Class.new do
      def initialize = @data = {}
      def read(key) = @data[key]
      def write(key, value, **) = @data[key] = value
      def delete(key) = @data.delete(key)
    end.new
    schema = { "object" => "data_source", "properties" => { "Name" => { "type" => "title" } } }
    client = Notion::Client.new(
      token: "token", cache: cache, adapter: Notion::Testing::Adapter.new(schema), rate: 1000
    )

    expect(client.schema_for("source")).to eq("Name" => { "type" => "title" })
    cached = Notion::Client.new(
      token: "token", cache: cache, adapter: Notion::Testing::Adapter.new, rate: 1000
    )
    expect(cached.schema_for("source")).to eq("Name" => { "type" => "title" })
    expect(cached.clear_schema_cache("source")).to be_nil
    expect(cache.read("notion:schema:source")).to be_nil
  end
end
