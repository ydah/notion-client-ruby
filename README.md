<h1 align="center">notion-client-ruby</h1>

<p align="center">
  <strong>A modern, dependency-free Ruby client for the Notion API</strong>
</p>

<p align="center">
  <a href="https://github.com/ydah/notion-client-ruby/actions/workflows/main.yml"><img src="https://github.com/ydah/notion-client-ruby/actions/workflows/main.yml/badge.svg" alt="CI"></a>
  <img src="https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg" alt="Ruby Version">
  <a href="LICENSE.txt"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
</p>

<p align="center">
  <a href="#features">Features</a> ·
  <a href="#installation">Installation</a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="#configuration">Configuration</a> ·
  <a href="#how-it-works">How It Works</a> ·
  <a href="#integrations">Integrations</a> ·
  <a href="#guides">Guides</a>
</p>

---

`notion-client-ruby` provides a small, resilient interface to the current Notion Public API. It covers the bundled official OpenAPI specification while keeping raw requests available for newly released endpoints.

## Features

<a name="features"></a>

- Generated endpoint groups for the complete bundled API specification
- Support for API versions `2022-06-28`, `2025-09-03`, and `2026-03-11`
- Ruby objects that preserve unknown response fields
- Lazy pagination and schema-aware query building
- Automatic retries, rate limiting, logging, and instrumentation
- Block building, concurrent batches, file uploads, OAuth, and webhooks
- No runtime dependencies

## Installation

<a name="installation"></a>

Until the first RubyGems release, add the GitHub repository to your Gemfile:

```ruby
gem "notion-client-ruby", github: "ydah/notion-client-ruby"
```

Then install:

```bash
bundle install
```

### Requirements

<a name="requirements"></a>

- Ruby 3.2+
- A Notion integration token

## Quick Start

<a name="quick-start"></a>

Create a client and call an endpoint group:

```ruby
require "notion"

client = Notion::Client.new(token: ENV.fetch("NOTION_TOKEN"))
me = client.users.me
page = client.pages.retrieve(page_id: "...")
```

Query a data source lazily:

```ruby
client.data_sources.query(data_source_id: "...") do |query|
  query.where(:Name).contains("roadmap")
  query.order(:Created, direction: :descending)
end.each_result { |result| puts result.title }
```

Build and append blocks:

```ruby
children = Notion.blocks do
  heading_1 "Design"
  paragraph "Small, boring, and resilient."
end

client.blocks.append_children(block_id: "...", children: children)
```

Use a raw request when an endpoint is newer than the bundled specification:

```ruby
client.request(:get, "/v1/users/me")
```

## Integrations

<a name="integrations"></a>

### Rails

The Railtie uses `Rails.logger` automatically. Generate an initializer with:

```bash
bin/rails generate notion:install
```

### Active Support

Requests publish `request.notion` events through `ActiveSupport::Notifications` when it is available. Rails-compatible cache stores can also be assigned to `config.cache`.

### Rack

`Notion::Webhooks::RackMiddleware` validates webhook signatures and handles subscription verification for Rack applications.

## Configuration

<a name="configuration"></a>

Configure shared defaults before creating clients:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `token` | String | `ENV["NOTION_TOKEN"]` | Notion integration token |
| `notion_version` | String | `ENV["NOTION_API_VERSION"]` or `"2026-03-11"` | API version sent with requests |
| `betas` | Array | `[]` | Notion beta versions sent with requests |
| `timeout` | Hash | `{ open: 5, read: 65 }` | Connection and response timeouts in seconds |
| `retry` | Hash | `{ max_attempts: 5, cap: 30 }` | Retry limit and maximum backoff in seconds |
| `rate_limit` | Hash | `{ rate: 3.0, burst: 6 }` | Request rate and burst capacity |
| `logger` | Logger | `nil` | Structured request logger |
| `cache` | Object | `nil` | Optional Rails-compatible cache store |
| `strict` | Boolean | `false` | Reject unknown schema properties |

### Example Configuration

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

Options passed to `Notion::Client.new` override the shared configuration for that client.

## How It Works

<a name="how-it-works"></a>

1. Endpoint Resolution maps a resource method to its generated API operation
2. Request Validation checks required path, query, and body parameters
3. Compatibility Translation adapts requests and responses for the selected API version
4. Middleware Processing applies authentication, rate limiting, retries, logging, and instrumentation
5. HTTP Transport sends the request through a pooled `Net::HTTP` adapter
6. Object Mapping converts the response into Ruby objects and deeply freezes the response data

Concurrent batches use the same client and preserve result order:

```ruby
pages = client.batch(concurrency: 3) do |batch|
  page_ids.each { |id| batch.call { client.pages.retrieve(page_id: id) } }
end
```

APIs under `client.experimental` may change outside the normal semantic-versioning guarantees.

## Guides

<a name="guides"></a>

- [Pagination](docs/recipes/pagination.md)
- [File uploads](docs/recipes/uploads.md)
- [OAuth](docs/recipes/oauth.md)
- [Webhooks](docs/recipes/webhooks.md)
- [Page synchronization](docs/recipes/page-sync.md)
- [CSV import](docs/recipes/csv-import.md)

## Development

<a name="development"></a>

```bash
bundle install
bundle exec rake
gem build notion-client.gemspec
```

Live tests use the variables documented in [`.env.example`](.env.example). Run `benchmark/load.rb` and `benchmark/objects.rb` to verify the performance budgets.

## License

<a name="license"></a>

Released under the [MIT License](LICENSE.txt).
