# notion-client-ruby

A dependency-free Ruby client for the current Notion Public API. It covers all 45 paths in the official OpenAPI document, preserves unknown response fields, retries transient failures, and supports API versions `2022-06-28`, `2025-09-03`, and `2026-03-11`.

## Installation

Until the first RubyGems release, install from a local checkout:

```ruby
gem "notion-client-ruby", path: "../notion-client-ruby"
```

Then:

```ruby
require "notion"

client = Notion::Client.new(token: ENV.fetch("NOTION_TOKEN"))
me = client.users.me
puts me.name
```

## Usage

Generated endpoint groups mirror the API:

```ruby
page = client.pages.retrieve(page_id: "...")
client.pages.update(page_id: page.id, in_trash: true)

client.data_sources.query(data_source_id: "...") do |query|
  query.where(:Name).contains("roadmap")
  query.order(:Created, direction: :descending)
end.each_result { |result| puts result.title }
```

Build blocks without another dependency:

```ruby
children = Notion.blocks do
  heading_1 "Design"
  paragraph "Small, boring, and resilient."
end

client.blocks.append_children(block_id: "...", children: children)
```

Raw requests remain available for endpoints newer than the bundled spec:

```ruby
client.request(:get, "/v1/users/me")
```

Configuration can be shared:

```ruby
Notion.configure do |config|
  config.token = ENV.fetch("NOTION_TOKEN")
  config.notion_version = "2026-03-11"
  config.timeout = { open: 5, read: 65 }
  config.retry = { max_attempts: 5, cap: 30 }
  config.rate_limit = { rate: 3.0, burst: 6, store: :memory }
  config.cache = Rails.cache if defined?(Rails.cache)
  config.logger = Logger.new($stdout)
end
```

File uploads, OAuth, webhooks, enhanced Markdown endpoints, local Markdown conversion, async task polling, and view query cleanup are included. See [`docs/recipes`](docs/recipes).

## Development

```sh
bundle install
bundle exec rake
```

`rake` runs specs and generated-code verification. Live tests require the variables documented in `.env.example` and are intentionally not run for pull requests from forks.

With a test connection and writable parent page configured, `bundle exec rake test:bootstrap` creates the database and two data sources required by compatibility smoke tests and prints their IDs.

The supported Ruby matrix is 3.2–4.0. `require "notion"` is kept below 50ms and parsing 1,000 pages below 200ms; run `benchmark/load.rb` and `benchmark/objects.rb` to verify both budgets. Clients are thread-safe; Ractor sharing is not supported.

Run independent requests concurrently while preserving result order:

```ruby
pages = client.batch(concurrency: 3) do |batch|
  page_ids.each { |id| batch.call { client.pages.retrieve(page_id: id) } }
end
```

APIs under `client.experimental` may change outside the normal semantic-versioning guarantees.

## License

MIT
