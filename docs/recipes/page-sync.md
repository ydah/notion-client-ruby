# Page synchronization

Store each page's `id` and `last_edited_time`. On later runs, query only changed rows:

```ruby
client.data_sources.sync_since(data_source_id: id, time: last_sync)
      .each_result { |page| upsert(page.id, page.raw) }
```

Webhook events are signals, not complete page snapshots; retrieve the page again before persisting it.
