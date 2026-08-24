# Large queries

```ruby
client.data_sources.query(data_source_id: id, page_size: 100)
      .each_result
      .lazy
      .take(1_000)
      .each { |page| process(page) }
```
