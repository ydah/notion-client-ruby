# frozen_string_literal: true

require_relative "transport"
require_relative "transport/net_http_adapter"
require_relative "compat"
require_relative "middleware"
require_relative "objects"
require_relative "pagination/cursor_paginator"
require_relative "query"
require_relative "blocks"
require_relative "batch"
require_relative "resolver"
require_relative "multipart"
require_relative "file_uploader"
require_relative "experimental"
require_relative "endpoints/base"
require_relative "generated"
require_relative "endpoints/blocks"
require_relative "endpoints/data_sources"
require_relative "endpoints/pages"
require_relative "endpoints/file_uploads"
require_relative "endpoints/async_tasks"
require_relative "endpoints/views"

module Notion
  class Client
    attr_reader :config

    def initialize(base_url: "https://api.notion.com", **options)
      @config = Notion.configuration.merge(**options)
      @config.betas = @config.betas.dup.freeze
      @config.freeze
      adapter = @config.adapter
      adapter = nil if adapter == :net_http
      adapter ||= Transport::NetHTTPAdapter.new(@config, base_url: base_url)
      @app = Middleware::Stack.build(adapter, @config)
      @endpoints = {}
      @endpoints_mutex = Mutex.new
      @resolver = Resolver.new(self)
      @file_uploader = FileUploader.new(self)
      @schema_cache = {}
      @schema_mutex = Mutex.new
    end

    def request(method, path, query: {}, headers: {}, body: nil, idempotent: nil)
      method = method.to_sym
      raise ArgumentError, "path must start with /" unless path.start_with?("/")

      response = @app.call(
        Transport::Request.new(
          verb: method,
          path: path,
          query: query.compact,
          headers: headers.transform_keys { |key| key.to_s.downcase },
          body: body,
          idempotent: idempotent.nil? ? %i[get delete].include?(method) : idempotent
        )
      )
      raise APIError.from_response(response) unless response.status.between?(200, 299)

      ObjectFactory.build(response.body)
    end

    def inspect
      "#<#{self.class} notion_version=#{config.notion_version.inspect}>"
    end

    Generated::RESOURCES.each_key do |resource|
      define_method(resource) { endpoint(resource) }
    end

    def search(**params, &)
      endpoint(:search).search(**params, &)
    end

    def resolve_data_source(database_id:, name: nil)
      @resolver.resolve(database_id, name: name)
    end

    def query(id, name: nil, **params, &)
      return data_sources.query(data_source_id: id, **params, &) if config.notion_version == "2022-06-28"

      data_source_id = resolve_data_source(database_id: id, name: name)
      data_sources.query(data_source_id: data_source_id, **params, &)
    rescue ObjectNotFoundError
      data_sources.query(data_source_id: id, **params, &)
    end

    def upload_file(**)
      @file_uploader.upload(**)
    end

    def import_file(**)
      @file_uploader.import(**)
    end

    def batch(concurrency: 3)
      raise ArgumentError, "a batch block is required" unless block_given?

      jobs = Batch.new(concurrency)
      yield jobs
      jobs.run
    end

    def experimental
      @endpoints_mutex.synchronize { @experimental ||= Experimental.new(self) }
    end

    def schema_for(data_source_id)
      cache_key = "notion:schema:#{data_source_id}"
      external = config.cache&.read(cache_key)
      return external if external

      @schema_mutex.synchronize do
        @schema_cache[data_source_id] ||= begin
          schema = data_sources.retrieve(data_source_id: data_source_id).raw.fetch("properties", {})
          config.cache&.write(cache_key, schema, expires_in: 900)
          schema
        end
      end
    end

    def clear_schema_cache(data_source_id = nil)
      config.cache&.delete("notion:schema:#{data_source_id}") if data_source_id
      @schema_mutex.synchronize do
        data_source_id ? @schema_cache.delete(data_source_id) : @schema_cache.clear
      end
    end

    private

    def endpoint(resource)
      @endpoints_mutex.synchronize do
        @endpoints[resource] ||= Generated::RESOURCES.fetch(resource).new(self)
      end
    end
  end
end
