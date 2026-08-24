# CSV import

```ruby
require "csv"

CSV.foreach("tasks.csv", headers: true) do |row|
  client.pages.create(
    parent: { data_source_id: data_source_id },
    properties: row.to_h
  )
end
```

Property values are converted using the data source schema. Enable `strict: true` to reject unknown CSV headers before creating a page.
