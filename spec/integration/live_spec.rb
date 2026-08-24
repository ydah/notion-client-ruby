# frozen_string_literal: true

RSpec.describe "Notion live API", :live do
  let(:client) { Notion::Client.new(token: ENV.fetch("NOTION_TEST_TOKEN")) }

  around do |example|
    WebMock.allow_net_connect!
    example.run
  ensure
    WebMock.disable_net_connect!
  end

  it "retrieves the current bot user" do
    expect(client.users.me.id).to be_a(String)
  end

  it "retrieves a shared page" do
    page = client.pages.retrieve(page_id: required_env("NOTION_TEST_PAGE_ID"))

    expect(page).to be_a(Notion::Objects::Page)
  end

  it "queries a data source" do
    list = client.data_sources.query(data_source_id: required_env("NOTION_TEST_DATA_SOURCE_ID"))

    expect(list).to be_a(Notion::Objects::List)
  end

  it "rejects an ambiguous multi-source database" do
    required_env("NOTION_TEST_SECONDARY_DATA_SOURCE_ID")

    expect { client.resolve_data_source(database_id: required_env("NOTION_TEST_DATABASE_ID")) }
      .to raise_error(Notion::AmbiguousDataSourceError)
  end

  def required_env(name)
    ENV.fetch(name) { skip "#{name} is not configured" }
  end
end
