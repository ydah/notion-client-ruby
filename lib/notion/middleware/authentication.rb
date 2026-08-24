# frozen_string_literal: true

module Notion
  module Middleware
    class Authentication
      def initialize(app, config)
        @app = app
        @config = config
        @refresh_mutex = Mutex.new
      end

      def call(request)
        token = access_token
        raise ConfigurationError, "token is required" if token.nil? || token.empty?

        headers = request.headers.merge(
          "authorization" => "Bearer #{token}",
          "user-agent" => @config.user_agent
        )
        @app.call(request.with(headers: headers))
      end

      private

      def access_token
        token = @config.token_store&.read(@config.token_key)
        token = refresh_expired(token) if expired?(token) && @config.auto_refresh
        token&.access_token || @config.token
      end

      def refresh_expired(token)
        @refresh_mutex.synchronize do
          current = @config.token_store.read(@config.token_key)
          expired?(current) ? refresh(current || token) : current
        end
      end

      def expired?(token)
        token&.expires_at && token.expires_at <= Time.now
      end

      def refresh(token)
        raise ConfigurationError, "oauth_client is required for token refresh" unless @config.oauth_client
        raise ConfigurationError, "refresh token is missing" unless token.refresh_token

        refreshed = @config.oauth_client.refresh(refresh_token: token.refresh_token)
        @config.token_store.write(@config.token_key, refreshed)
        refreshed
      end
    end
  end
end
