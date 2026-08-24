# notion-client-ruby

A modern, dependency-free Ruby client for the Notion API.

[![CI](https://github.com/ydah/notion-client-ruby/actions/workflows/main.yml/badge.svg)](https://github.com/ydah/notion-client-ruby/actions/workflows/main.yml)

[Features](#features) · [Installation](#installation) · [Quick Start](#quick-start) · [Configuration](#configuration) · [Guides](#guides) · [Development](#development)

---

`notion-client-ruby` provides a small, resilient interface to the current Notion Public API. It covers the bundled official OpenAPI document while keeping raw requests available for newly released endpoints.

## Features

- Supports Notion API versions `2022-06-28`, `2025-09-03`, and `2026-03-11`
- Exposes generated endpoint groups for the complete bundled API specification
- Preserves unknown response fields for forward compatibility
- Handles pagination, retries, rate limiting, logging, and instrumentation
- Includes query and block builders, concurrent batches, uploads, OAuth, and webhooks
- Supports Ruby 3.2 through 4.0 with no runtime dependencies

## Installation

Until the first RubyGems release, install from a local checkout:

```ruby
gem "notion-client-ruby", path: "../notion-client-ruby"
```

Then require the library:

```ruby
require "notion"
```

Ruby 3.2 or newer is required.

## Quick Start

Create a client with an integration token and call an endpoint group:

```ruby
client = Notion::Client.new(token: ENV.fetch("NOTION_TOKEN"))

me = client.users.me
page = client.pages.retrieve(page_id: "...")
client.pages.update(page_id: page.id, in_trash: true)
```

Queries can be built with Ruby methods and paginated lazily:

```ruby
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

For endpoints newer than the bundled specification, use a raw request:

```ruby
client.request(:get, "/v1/users/me")
```

## Configuration

Configure shared defaults before creating clients:

```ruby
require "logger"

Notion.configure do |config|
  config.token = ENV.fetch("NOTION_TOKEN")
  config.notion_version = "2026-03-11"
  config.timeout = { open: 5, read: 65 }
  config.retry = { max_attempts: 5, cap: 30 }
  config.rate_limit = { rate: 3.0, burst: 6 }
  config.logger = Logger.new($stdout)
end
```

| Option | Default | Description |
| --- | --- | --- |
| `token` | `ENV["NOTION_TOKEN"]` | Notion integration token |
| `notion_version` | `ENV["NOTION_API_VERSION"]` or `2026-03-11` | API version sent with requests |
| `timeout` | `{ open: 5, read: 65 }` | Connection and response timeouts in seconds |
| `retry` | `{ max_attempts: 5, cap: 30 }` | Retry limit and maximum backoff in seconds |
| `rate_limit` | `{ rate: 3.0, burst: 6 }` | Client-side request rate and burst capacity |
| `logger` | `nil` | Logger used for structured request logs |
| `cache` | `nil` | Optional Rails-compatible cache store |

Options passed to `Notion::Client.new` override the shared configuration for that client.

Run independent requests concurrently while preserving result order:

```ruby
pages = client.batch(concurrency: 3) do |batch|
  page_ids.each { |id| batch.call { client.pages.retrieve(page_id: id) } }
end
```

APIs under `client.experimental` may change outside the normal semantic-versioning guarantees.

## Guides

- [Pagination](docs/recipes/pagination.md)
- [File uploads](docs/recipes/uploads.md)
- [OAuth](docs/recipes/oauth.md)
- [Webhooks](docs/recipes/webhooks.md)
- [Page synchronization](docs/recipes/page-sync.md)
- [CSV import](docs/recipes/csv-import.md)

## Development

```sh
bundle install
bundle exec rake
```

`rake` runs the specs and verifies generated code. Live tests use the variables documented in [`.env.example`](.env.example) and are not run for pull requests from forks.

The library keeps `require "notion"` below 50ms and parses 1,000 pages below 200ms. Run `benchmark/load.rb` and `benchmark/objects.rb` to verify both budgets.

## License

[MIT](LICENSE.txt)
