# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class DataSources < Notion::Endpoints::Base
      operation :retrieve, :get, "/v1/data_sources/{data_source_id}", path: ["data_source_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :update, :patch, "/v1/data_sources/{data_source_id}", path: ["data_source_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :query, :post, "/v1/data_sources/{data_source_id}/query", path: ["data_source_id"], query: ["filter_properties"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {"result_type" => ["page", "data_source"]}, max_lengths: {} }
      operation :create, :post, "/v1/data_sources", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["parent", "properties"], variants: [["parent", "properties"]], enums: {}, max_lengths: {} }
      operation :templates, :get, "/v1/data_sources/{data_source_id}/templates", path: ["data_source_id"], query: ["name", "start_cursor", "page_size"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }

    # Retrieve a data source
    # @see https://developers.notion.com/reference/retrieve-a-data-source
    def retrieve(data_source_id:, **params, &block)
        params[:data_source_id] = data_source_id
      invoke_operation(:retrieve, params, &block)
    end
    # Update a data source
    # @see https://developers.notion.com/reference/update-a-data-source
    def update(data_source_id:, **params, &block)
        params[:data_source_id] = data_source_id
      invoke_operation(:update, params, &block)
    end
    # Query a data source
    # @see https://developers.notion.com/reference/post-database-query
    def query(data_source_id:, **params, &block)
        params[:data_source_id] = data_source_id
      invoke_operation(:query, params, &block)
    end
    # Create a data source
    # @see https://developers.notion.com/reference/create-a-database
    def create(parent:, properties:, **params, &block)
        params[:parent] = parent
        params[:properties] = properties
      invoke_operation(:create, params, &block)
    end
    # List templates in a data source
    # @see https://developers.notion.com/reference/list-data-source-templates
    def templates(data_source_id:, **params, &block)
        params[:data_source_id] = data_source_id
      invoke_operation(:templates, params, &block)
    end
      end
    end
  end
end
