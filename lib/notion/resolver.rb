# frozen_string_literal: true

module Notion
  class AmbiguousDataSourceError < Error; end
  class DataSourceNotFoundError < Error; end

  class Resolver
    TTL = 900
    MAX_CACHE_SIZE = 100

    def initialize(client, clock: Process.method(:clock_gettime))
      @client = client
      @clock = clock
      @store = client.config.cache if client.respond_to?(:config)
      @cache = {}
      @mutex = Mutex.new
    end

    def resolve(database_id, name: nil)
      key = [database_id, name]
      external = @store&.read(cache_key(key))
      return external if external

      cached = cached_value(key)
      return cached if cached

      sources = Array(@client.databases.retrieve(database_id: database_id).data_sources)
      selected = select(sources, name)
      id = selected.fetch("id")
      write_cache(key, id)
      id
    end

    private

    def cached_value(key)
      @mutex.synchronize do
        expires_at, value = @cache.delete(key)
        fresh = expires_at && expires_at > monotonic
        @cache[key] = [expires_at, value] if fresh
        value if fresh
      end
    end

    def write_cache(key, value)
      @store&.write(cache_key(key), value, expires_in: TTL)
      @mutex.synchronize do
        @cache[key] = [monotonic + TTL, value]
        @cache.shift while @cache.length > MAX_CACHE_SIZE
      end
    end

    def cache_key(key)
      "notion:data_source:#{key.compact.join(':')}"
    end

    def select(sources, name)
      if name
        source = sources.find { |candidate| candidate["name"] == name }
        return source || raise(DataSourceNotFoundError, "data source not found")
      end
      return sources.first if sources.one?
      raise DataSourceNotFoundError, "database contains no data sources" if sources.empty?

      raise AmbiguousDataSourceError, "database contains #{sources.length} data sources; pass name:"
    end

    def monotonic
      @clock.call(Process::CLOCK_MONOTONIC)
    end
  end
end
