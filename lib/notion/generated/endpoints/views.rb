# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Views < Notion::Endpoints::Base
      operation :list, :get, "/v1/views", path: [], query: ["database_id", "data_source_id", "start_cursor", "page_size"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :create, :post, "/v1/views", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["data_source_id", "name", "type"], variants: [["data_source_id", "name", "type"]], enums: {"type" => ["table", "board", "list", "calendar", "timeline", "gallery", "form", "chart", "map", "dashboard"]}, max_lengths: {} }
      operation :retrieve, :get, "/v1/views/{view_id}", path: ["view_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :update, :patch, "/v1/views/{view_id}", path: ["view_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :delete, :delete, "/v1/views/{view_id}", path: ["view_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :create_query, :post, "/v1/views/{view_id}/queries", path: ["view_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :query_results, :get, "/v1/views/{view_id}/queries/{query_id}", path: ["view_id", "query_id"], query: ["start_cursor", "page_size"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :delete_query, :delete, "/v1/views/{view_id}/queries/{query_id}", path: ["view_id", "query_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }

    # List views
    # @see https://developers.notion.com/reference/list-views
    def list(**params, &block)

      invoke_operation(:list, params, &block)
    end
    # Create a view
    # @see https://developers.notion.com/reference/create-view
    def create(data_source_id:, name:, type:, **params, &block)
        params[:data_source_id] = data_source_id
        params[:name] = name
        params[:type] = type
      invoke_operation(:create, params, &block)
    end
    # Retrieve a view
    # @see https://developers.notion.com/reference/retrieve-a-view
    def retrieve(view_id:, **params, &block)
        params[:view_id] = view_id
      invoke_operation(:retrieve, params, &block)
    end
    # Update a view
    # @see https://developers.notion.com/reference/update-a-view
    def update(view_id:, **params, &block)
        params[:view_id] = view_id
      invoke_operation(:update, params, &block)
    end
    # Delete a view
    # @see https://developers.notion.com/reference/delete-view
    def delete(view_id:, **params, &block)
        params[:view_id] = view_id
      invoke_operation(:delete, params, &block)
    end
    # Create a view query
    # @see https://developers.notion.com/reference/create-view-query
    def create_query(view_id:, **params, &block)
        params[:view_id] = view_id
      invoke_operation(:create_query, params, &block)
    end
    # Get view query results
    # @see https://developers.notion.com/reference/get-view-query-results
    def query_results(view_id:, query_id:, **params, &block)
        params[:view_id] = view_id
        params[:query_id] = query_id
      invoke_operation(:query_results, params, &block)
    end
    # Delete a view query
    # @see https://developers.notion.com/reference/delete-view-query
    def delete_query(view_id:, query_id:, **params, &block)
        params[:view_id] = view_id
        params[:query_id] = query_id
      invoke_operation(:delete_query, params, &block)
    end
      end
    end
  end
end
