# File uploads

```ruby
upload = client.upload_file(path: "report.pdf", content_type: "application/pdf")
```

Files over 20 MiB use the multipart API automatically. Pass `on_progress:` for progress notifications. External imports accept only HTTP(S) URLs.

`client.import_file(url: ...)` waits for the asynchronous import by default. Pass `wait: false` to receive the pending upload immediately.
