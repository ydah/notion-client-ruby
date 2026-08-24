# frozen_string_literal: true

RSpec.describe Notion::Resolver do
  it "resolves a named source and caches it" do
    calls = 0
    databases = Object.new
    databases.define_singleton_method(:retrieve) do |database_id:|
      calls += 1
      raise "unexpected id" unless database_id == "db"

      Notion::Objects::Database.new(
        "data_sources" => [{ "id" => "first", "name" => "Tasks" }, { "id" => "second", "name" => "Notes" }]
      )
    end
    client = Object.new
    client.define_singleton_method(:databases) { databases }
    resolver = described_class.new(client)

    expect(resolver.resolve("db", name: "Tasks")).to eq("first")
    expect(resolver.resolve("db", name: "Tasks")).to eq("first")
    expect(calls).to eq(1)
  end

  it "rejects an ambiguous database" do
    databases = Object.new
    databases.define_singleton_method(:retrieve) do |database_id:|
      Notion::Objects::Database.new("id" => database_id, "data_sources" => [{ "id" => "a" }, { "id" => "b" }])
    end
    client = Object.new
    client.define_singleton_method(:databases) { databases }

    expect { described_class.new(client).resolve("db") }.to raise_error(Notion::AmbiguousDataSourceError)
  end

  it "uses an injected ActiveSupport-compatible cache" do
    cache = Class.new do
      attr_reader :writes

      def initialize
        @data = {}
        @writes = []
      end

      def read(key) = @data[key]

      def write(key, value, **options)
        @writes << [key, value, options]
        @data[key] = value
      end
    end.new
    databases = Object.new
    databases.define_singleton_method(:retrieve) do |database_id:|
      Notion::Objects::Database.new("data_sources" => [{ "id" => "source", "name" => database_id }])
    end
    client = Struct.new(:databases, :config).new(databases, Struct.new(:cache).new(cache))

    expect(described_class.new(client).resolve("Tasks")).to eq("source")
    expect(described_class.new(client).resolve("Tasks")).to eq("source")
    expect(cache.writes.first.last).to eq(expires_in: 900)
  end
end
