# frozen_string_literal: true

Notion.configure do |config|
  config.token = ENV.fetch("NOTION_TOKEN")
end
