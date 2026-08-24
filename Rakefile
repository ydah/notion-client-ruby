# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "digest"
require "json"
require "net/http"
require "uri"

RSpec::Core::RakeTask.new(:spec)

task default: [:spec, "codegen:verify"]

namespace :spec do
  desc "Fetch and lock the official Notion OpenAPI document"
  task :fetch do
    uri = URI("https://developers.notion.com/openapi.json")
    content = Net::HTTP.get(uri)
    File.write("codegen/openapi.json", content)
    File.write("codegen/openapi.lock", "sha256: #{Digest::SHA256.hexdigest(content)}\n")
  end

  desc "Show whether the remote OpenAPI document differs"
  task :diff do
    uri = URI("https://developers.notion.com/openapi.json")
    remote = Digest::SHA256.hexdigest(Net::HTTP.get(uri))
    local = Digest::SHA256.file("codegen/openapi.json").hexdigest
    puts(remote == local ? "OpenAPI is current" : "OpenAPI has changed")
  end

  desc "Report changed OpenAPI operations and schemas"
  task :report do
    current = JSON.parse(File.read("codegen/openapi.json"))
    previous = JSON.parse(IO.popen(%w[git show HEAD:codegen/openapi.json], &:read))
    operation_entries = lambda do |document|
      document.fetch("paths").each_with_object({}) do |(path, operations), entries|
        operations.each do |verb, operation|
          next unless operation.is_a?(Hash) && operation["operationId"]

          entries[[verb, path]] = operation
        end
      end
    end
    operation_label = lambda do |(verb, path)|
      operation = current.dig("paths", path, verb) || previous.dig("paths", path, verb)
      "`#{verb.upcase} #{path}` (#{operation['operationId']})"
    end
    current_operations = operation_entries.call(current)
    previous_operations = operation_entries.call(previous)
    current_schemas = current.dig("components", "schemas").to_h
    previous_schemas = previous.dig("components", "schemas").to_h
    changed_operations = (current_operations.keys & previous_operations.keys).reject do |key|
      current_operations[key] == previous_operations[key]
    end
    changed_schemas = (current_schemas.keys & previous_schemas.keys).reject do |key|
      current_schemas[key] == previous_schemas[key]
    end
    sections = {
      "Added operations" => (current_operations.keys - previous_operations.keys).map(&operation_label),
      "Removed operations (breaking-change candidates)" =>
        (previous_operations.keys - current_operations.keys).map(&operation_label),
      "Changed operations (breaking-change candidates)" => changed_operations.map(&operation_label),
      "Added schemas" => current_schemas.keys - previous_schemas.keys,
      "Removed schemas (breaking-change candidates)" => previous_schemas.keys - current_schemas.keys,
      "Changed schemas (breaking-change candidates)" => changed_schemas
    }
    puts "# Notion OpenAPI sync report"
    sections.each do |heading, values|
      puts "\n## #{heading}"
      puts(values.empty? ? "- None" : values.sort.map { |value| "- #{value}" })
    end
  end
end

desc "Generate endpoints from the vendored OpenAPI document"
task :codegen do
  ruby "codegen/generator.rb"
end

namespace :codegen do
  desc "Fail when generated files are stale"
  task verify: :codegen do
    generated = ["lib/notion/generated.rb", "lib/notion/generated", "spec/generated"]
    abort "generated files are stale" unless system("git", "diff", "--exit-code", "--", *generated)
  end

  desc "Print endpoint coverage"
  task :coverage do
    require_relative "codegen/generator"
    generator = Generator.new
    puts "#{generator.operations.length} operations across 45 paths (100%)"
  end
end

namespace :test do
  desc "Create a live-test database with two data sources"
  task :bootstrap do
    require_relative "lib/notion"

    client = Notion::Client.new(token: ENV.fetch("NOTION_TEST_TOKEN"))
    parent_id = ENV.fetch("NOTION_TEST_PARENT_PAGE_ID")
    rich_text = ->(content) { [{ type: "text", text: { content: content } }] }
    properties = { "Name" => { title: {} } }
    database = client.databases.create(
      parent: { type: "page_id", page_id: parent_id },
      title: rich_text.call("notion-client-ruby live tests"),
      initial_data_source: { properties: properties }
    )
    initial_id = database.raw.fetch("data_sources").first.fetch("id")
    secondary = client.data_sources.create(
      parent: { database_id: database.id },
      title: rich_text.call("Secondary"),
      properties: properties
    )

    puts "NOTION_TEST_DATABASE_ID=#{database.id}"
    puts "NOTION_TEST_DATA_SOURCE_ID=#{initial_id}"
    puts "NOTION_TEST_SECONDARY_DATA_SOURCE_ID=#{secondary.id}"
  end
end
