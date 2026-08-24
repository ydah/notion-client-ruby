# frozen_string_literal: true

module Notion
  class ConfigurationError < StandardError; end

  class Config
    API_VERSIONS = %w[2022-06-28 2025-09-03 2026-03-11].freeze

    attr_accessor :token, :notion_version, :betas, :open_timeout, :read_timeout,
                  :max_attempts, :retry_cap, :rate, :burst, :logger, :log_level,
                  :user_agent, :ca_file, :proxy, :strict, :adapter, :token_store,
                  :token_key, :oauth_client, :auto_refresh, :cache, :rate_limit_store

    def initialize
      @token = ENV.fetch("NOTION_TOKEN", nil)
      @notion_version = ENV.fetch("NOTION_API_VERSION", "2026-03-11")
      @betas = []
      @open_timeout = 5
      @read_timeout = 65
      @max_attempts = 5
      @retry_cap = 30
      @rate = 3.0
      @burst = 6
      @log_level = :info
      @user_agent = "notion-client-ruby/#{Notion::VERSION} (ruby/#{RUBY_VERSION})"
      @strict = false
      @token_key = :default
      @auto_refresh = false
    end

    def timeout=(values)
      self.open_timeout = values.fetch(:open, open_timeout)
      self.read_timeout = values.fetch(:read, read_timeout)
    end

    def retry=(values)
      self.max_attempts = values.fetch(:max_attempts, max_attempts)
      self.retry_cap = values.fetch(:cap, retry_cap)
    end

    def rate_limit=(values)
      self.rate = values.fetch(:rate, rate)
      self.burst = values.fetch(:burst, burst)
      self.rate_limit_store = values[:store] == :memory ? nil : values[:store] if values.key?(:store)
    end

    def validate!(require_token: false)
      raise ConfigurationError, "token is required" if require_token && blank?(@token) && !@token_store
      unless API_VERSIONS.include?(@notion_version)
        raise ConfigurationError, "unsupported Notion API version: #{@notion_version}"
      end

      positive_values.each do |name, value|
        raise ConfigurationError, "#{name} must be positive" unless value.to_f.positive?
      end

      self
    end

    def merge(**options)
      copy = dup
      options.each do |name, value|
        writer = "#{name}="
        raise ConfigurationError, "unknown option: #{name}" unless copy.respond_to?(writer)

        copy.public_send(writer, value)
      end
      copy.validate!
    end

    private

    def positive_values
      {
        open_timeout: @open_timeout,
        read_timeout: @read_timeout,
        max_attempts: @max_attempts,
        retry_cap: @retry_cap,
        rate: @rate,
        burst: @burst
      }
    end

    def blank?(value)
      value.nil? || value.empty?
    end
  end
end
