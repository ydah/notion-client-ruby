# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Databases < Notion::Endpoints::Base
      operation :retrieve, :get, "/v1/databases/{database_id}", path: ["database_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :update, :patch, "/v1/databases/{database_id}", path: ["database_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :create, :post, "/v1/databases", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["parent"], variants: [["parent"]], enums: {}, max_lengths: {} }

    # Retrieve a database
    # @see https://developers.notion.com/reference/retrieve-database
    def retrieve(database_id:, **params, &block)
        params[:database_id] = database_id
      invoke_operation(:retrieve, params, &block)
    end
    # Update a database
    # @see https://developers.notion.com/reference/update-database
    def update(database_id:, **params, &block)
        params[:database_id] = database_id
      invoke_operation(:update, params, &block)
    end
    # Create a database
    # @see https://developers.notion.com/reference/create-database
    def create(parent:, **params, &block)
        params[:parent] = parent
      invoke_operation(:create, params, &block)
    end
      end
    end
  end
end
