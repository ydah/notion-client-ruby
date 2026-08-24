# frozen_string_literal: true

require "rake"

RSpec.describe "test:bootstrap rake task" do
  let(:properties) { { "Name" => { title: {} } } }
  let(:database) do
    Notion::Objects::Database.new(
      "object" => "database", "id" => "database", "data_sources" => [{ "id" => "primary" }]
    )
  end
  let(:secondary) { Notion::Objects::DataSource.new("object" => "data_source", "id" => "secondary") }
  let(:client) { double(databases: spy, data_sources: spy) }

  before do
    load File.expand_path("../../Rakefile", __dir__) unless Rake::Task.task_defined?("test:bootstrap")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("NOTION_TEST_TOKEN").and_return("token")
    allow(ENV).to receive(:fetch).with("NOTION_TEST_PARENT_PAGE_ID").and_return("parent")
    allow(Notion::Client).to receive(:new).with(token: "token").and_return(client)
    allow(client.databases).to receive(:create).and_return(database)
    allow(client.data_sources).to receive(:create).and_return(secondary)
    Rake::Task["test:bootstrap"].reenable
  end

  it "creates a database with two data sources and prints their IDs" do
    expect { Rake::Task["test:bootstrap"].invoke }.to output(
      /NOTION_TEST_DATABASE_ID=database.*NOTION_TEST_DATA_SOURCE_ID=primary.*SECONDARY_DATA_SOURCE_ID=secondary/m
    ).to_stdout
    expect(client.databases).to have_received(:create).with(
      parent: { type: "page_id", page_id: "parent" },
      title: [{ type: "text", text: { content: "notion-client-ruby live tests" } }],
      initial_data_source: { properties: properties }
    )
    expect(client.data_sources).to have_received(:create).with(
      parent: { database_id: "database" },
      title: [{ type: "text", text: { content: "Secondary" } }],
      properties: properties
    )
  end
end
