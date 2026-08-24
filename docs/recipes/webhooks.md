# Webhooks

```ruby
use Notion::Webhooks::RackMiddleware, secret: ENV.fetch("NOTION_WEBHOOK_SECRET") do |event|
  EventJob.perform_later(event.raw)
end
```

The middleware verifies Notion's `X-Notion-Signature` raw-body HMAC in constant time. Initial verification-token requests are acknowledged automatically.

The same middleware works in Sinatra:

```ruby
class WebhookApp < Sinatra::Base
  use Notion::Webhooks::RackMiddleware, secret: ENV.fetch("NOTION_WEBHOOK_SECRET") do |event|
    Events.process(event.raw)
  end
end
```

In Rails, add it to `config/application.rb`:

```ruby
config.middleware.use Notion::Webhooks::RackMiddleware,
                      secret: ENV.fetch("NOTION_WEBHOOK_SECRET") do |event|
  EventJob.perform_later(event.raw)
end
```
