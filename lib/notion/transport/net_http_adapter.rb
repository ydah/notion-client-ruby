# frozen_string_literal: true

require "net/http"
require "uri"

module Notion
  module Transport
    class NetHTTPAdapter < Adapter
      REQUEST_CLASSES = {
        delete: Net::HTTP::Delete,
        get: Net::HTTP::Get,
        head: Net::HTTP::Head,
        patch: Net::HTTP::Patch,
        post: Net::HTTP::Post,
        put: Net::HTTP::Put
      }.freeze

      def initialize(config, base_url: "https://api.notion.com", pool_size: 5, clock: Process.method(:clock_gettime))
        super()
        @config = config
        @base_uri = URI(base_url)
        @clock = clock
        @pool = SizedQueue.new(pool_size)
        pool_size.times { @pool << build_connection }
      end

      def call(request)
        http = @pool.pop
        broken = false
        started = monotonic
        http.start unless http.started?
        response = http.request(build_request(request))
        headers = response.each_header.to_h
        Response.new(
          status: response.code.to_i,
          headers: headers,
          body: response.body,
          request_id: headers["x-request-id"],
          elapsed: monotonic - started
        )
      rescue Timeout::Error => e
        broken = true
        raise TimeoutError.new(e.message, cause: e)
      rescue IOError, SocketError, SystemCallError => e
        broken = true
        raise TransportError.new(e.message, cause: e)
      ensure
        release(http, broken) if http
      end

      private

      def build_connection
        proxy = @config.proxy && URI(@config.proxy)
        klass = proxy ? Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password) : Net::HTTP
        http = klass.new(@base_uri.host, @base_uri.port)
        http.use_ssl = @base_uri.scheme == "https"
        http.open_timeout = @config.open_timeout
        http.read_timeout = @config.read_timeout
        http.ca_file = @config.ca_file if @config.ca_file
        http
      end

      def build_request(request)
        uri = @base_uri.dup
        uri.path = request.path
        uri.query = URI.encode_www_form(request.query) unless request.query.empty?
        klass = REQUEST_CLASSES.fetch(request.verb) do
          raise ArgumentError, "unsupported HTTP method: #{request.verb}"
        end
        klass.new(uri, request.headers).tap { |http_request| http_request.body = request.body if request.body }
      end

      def release(http, broken)
        if broken
          http.finish if http.started?
          @pool << build_connection
        else
          @pool << http
        end
      rescue IOError
        @pool << build_connection
      end

      def monotonic
        @clock.call(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
