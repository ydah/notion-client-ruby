# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Notion
  module OAuth
    Token = Data.define(:access_token, :refresh_token, :bot_id, :workspace_id, :expires_at, :raw)

    class Client
      def initialize(client_id:, client_secret:, redirect_uri:, base_url: "https://api.notion.com")
        @client_id = client_id
        @client_secret = client_secret
        @redirect_uri = redirect_uri
        @base_url = base_url
      end

      def authorize_url(state:, owner: "user")
        query = URI.encode_www_form(
          client_id: @client_id,
          response_type: "code",
          owner: owner,
          redirect_uri: @redirect_uri,
          state: state
        )
        "https://api.notion.com/v1/oauth/authorize?#{query}"
      end

      def exchange(code:)
        token_request(grant_type: "authorization_code", code: code, redirect_uri: @redirect_uri)
      end

      def refresh(refresh_token:)
        token_request(grant_type: "refresh_token", refresh_token: refresh_token)
      end

      def introspect(token:)
        request("/v1/oauth/introspect", token: token)
      end

      def revoke(token:)
        request("/v1/oauth/revoke", token: token)
      end

      private

      def token_request(**body)
        data = request("/v1/oauth/token", body)
        Token.new(
          access_token: data["access_token"],
          refresh_token: data["refresh_token"],
          bot_id: data["bot_id"],
          workspace_id: data["workspace_id"],
          expires_at: data["expires_in"] && (Time.now + data["expires_in"]),
          raw: data
        )
      end

      def request(path, body)
        uri = URI.join(@base_url, path)
        request = Net::HTTP::Post.new(uri)
        credentials = ["#{@client_id}:#{@client_secret}"].pack("m0")
        request["authorization"] = "Basic #{credentials}"
        request["content-type"] = "application/json"
        request.body = JSON.generate(body)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
        data = JSON.parse(response.body)
        raise Error, data["message"] || "OAuth request failed" unless response.is_a?(Net::HTTPSuccess)

        data
      end
    end

    class TokenStore
      def read(_key) = raise(NotImplementedError)
      def write(_key, _token) = raise(NotImplementedError)
    end

    class MemoryTokenStore < TokenStore
      def initialize
        super
        @tokens = {}
        @mutex = Mutex.new
      end

      def read(key) = @mutex.synchronize { @tokens[key] }
      def write(key, token) = @mutex.synchronize { @tokens[key] = token }
    end
  end
end
