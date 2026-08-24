# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Oauth < Notion::Endpoints::Base
      operation :token, :post, "/v1/oauth/token", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["grant_type"], variants: [["grant_type", "code"], ["grant_type", "refresh_token"]], enums: {}, max_lengths: {} }
      operation :revoke, :post, "/v1/oauth/revoke", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["token"], variants: [["token"]], enums: {}, max_lengths: {} }
      operation :introspect, :post, "/v1/oauth/introspect", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["token"], variants: [["token"]], enums: {}, max_lengths: {} }

    # Exchange an authorization code for an access and refresh token
    # @see https://developers.notion.com/reference/create-a-token
    def token(grant_type:, **params, &block)
        params[:grant_type] = grant_type
      invoke_operation(:token, params, &block)
    end
    # Revoke a token
    # @see https://developers.notion.com/reference/revoke-token
    def revoke(token:, **params, &block)
        params[:token] = token
      invoke_operation(:revoke, params, &block)
    end
    # Introspect a token
    # @see https://developers.notion.com/reference/introspect-token
    def introspect(token:, **params, &block)
        params[:token] = token
      invoke_operation(:introspect, params, &block)
    end
      end
    end
  end
end
