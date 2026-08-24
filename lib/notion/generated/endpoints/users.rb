# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Users < Notion::Endpoints::Base
      operation :me, :get, "/v1/users/me", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :retrieve, :get, "/v1/users/{user_id}", path: ["user_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :list, :get, "/v1/users", path: [], query: ["start_cursor", "page_size"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }

    # Retrieve your token's bot user
    # @see https://developers.notion.com/reference/get-self
    def me(**params, &block)

      invoke_operation(:me, params, &block)
    end
    # Retrieve a user
    # @see https://developers.notion.com/reference/get-user
    def retrieve(user_id:, **params, &block)
        params[:user_id] = user_id
      invoke_operation(:retrieve, params, &block)
    end
    # List all users
    # @see https://developers.notion.com/reference/get-users
    def list(**params, &block)

      invoke_operation(:list, params, &block)
    end
      end
    end
  end
end
