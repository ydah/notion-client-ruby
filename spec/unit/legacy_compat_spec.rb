# frozen_string_literal: true

require "notion/compat/legacy"

RSpec.describe "legacy compatibility" do
  it "delegates old page calls with a warning" do
    adapter = Notion::Testing::Adapter.new("object" => "page", "id" => "page")
    client = Notion::Client.new(token: "secret", adapter: adapter)

    expect { expect(client.page(page_id: "page").id).to eq("page") }
      .to output(/deprecated/).to_stderr
  end

  it "delegates the remaining legacy methods" do
    adapter = Notion::Testing::Adapter.new(
      { "object" => "database", "id" => "db" },
      { "object" => "page", "id" => "new" },
      { "object" => "list", "results" => [], "has_more" => false, "next_cursor" => nil }
    )
    client = Notion::Client.new(token: "secret", adapter: adapter)

    expect do
      expect(client.database(database_id: "db").id).to eq("db")
      expect(client.create_page(parent: { page_id: "parent" }).id).to eq("new")
      expect(client.block_children(block_id: "block")).to be_a(Notion::Objects::List)
    end.to output(/deprecated.*deprecated.*deprecated/m).to_stderr
  end

  it "enumerates legacy search blocks" do
    adapter = Notion::Testing::Adapter.new(
      "object" => "list", "results" => [{ "object" => "page", "id" => "page" }], "has_more" => false
    )
    client = Notion::Client.new(token: "token", adapter: adapter, rate: 1000)
    pages = []

    client.search(query: "task") { |page| pages << page.id }

    expect(pages).to eq(["page"])
  end
end
