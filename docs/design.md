# Architecture

The client is split into transport, middleware, generated endpoints, response objects, and optional ergonomics. The core uses only Ruby standard libraries.

Requests flow through instrumentation, redacted logging, retry, token-bucket rate limiting, authentication, API-version compatibility, and JSON encoding before `Net::HTTP`. Endpoint declarations and coverage specs are generated from the vendored official OpenAPI document. Unknown response fields and object types remain accessible through `raw` and `[]`.

Compatibility normalizes legacy `archived`, `after`, and `transcription` fields to the `2026-03-11` vocabulary. New endpoints remain reachable immediately through `Client#request` before a generated update is released.
