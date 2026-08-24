# frozen_string_literal: true

require "notion"

raw = {
  "object" => "list",
  "results" => Array.new(1000) { |index| { "object" => "page", "id" => index.to_s, "properties" => {} } }
}
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
results = Notion::ObjectFactory.build(raw).results
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

puts format("parse 1000 pages: %.2fms", elapsed * 1000)
abort "parse exceeded 200ms" if results.length != 1000 || elapsed >= 0.2
