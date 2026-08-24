# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Pages < Notion::Endpoints::Base
      operation :create, :post, "/v1/pages", path: [], query: ["filter_properties"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["parent"], variants: [["parent"]], enums: {}, max_lengths: {} }
      operation :retrieve, :get, "/v1/pages/{page_id}", path: ["page_id"], query: ["filter_properties"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :update, :patch, "/v1/pages/{page_id}", path: ["page_id"], query: ["filter_properties"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :move, :post, "/v1/pages/{page_id}/move", path: ["page_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["parent"], variants: [["parent"]], enums: {}, max_lengths: {} }
      operation :retrieve_property, :get, "/v1/pages/{page_id}/properties/{property_id}", path: ["page_id", "property_id"], query: ["start_cursor", "page_size"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :markdown, :get, "/v1/pages/{page_id}/markdown", path: ["page_id"], query: ["include_transcript"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :update_markdown, :patch, "/v1/pages/{page_id}/markdown", path: ["page_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["type"], variants: [["type", "insert_content"], ["type", "replace_content_range"], ["type", "update_content"], ["type", "replace_content"]], enums: {}, max_lengths: {} }

    # Create a page
    # @see https://developers.notion.com/reference/post-page
    def create(parent:, **params, &block)
        params[:parent] = parent
      invoke_operation(:create, params, &block)
    end
    # Retrieve a page
    # @see https://developers.notion.com/reference/retrieve-a-page
    def retrieve(page_id:, **params, &block)
        params[:page_id] = page_id
      invoke_operation(:retrieve, params, &block)
    end
    # Update page
    # @see https://developers.notion.com/reference/patch-page
    def update(page_id:, **params, &block)
        params[:page_id] = page_id
      invoke_operation(:update, params, &block)
    end
    # Move a page
    # @see https://developers.notion.com/reference/move-page
    def move(page_id:, parent:, **params, &block)
        params[:page_id] = page_id
        params[:parent] = parent
      invoke_operation(:move, params, &block)
    end
    # Retrieve a page property item
    # @see https://developers.notion.com/reference/retrieve-a-page-property
    def retrieve_property(page_id:, property_id:, **params, &block)
        params[:page_id] = page_id
        params[:property_id] = property_id
      invoke_operation(:retrieve_property, params, &block)
    end
    # Retrieve a page as markdown
    # @see https://developers.notion.com/reference/retrieve-page-markdown
    def markdown(page_id:, **params, &block)
        params[:page_id] = page_id
      invoke_operation(:markdown, params, &block)
    end
    # Update a page's content as markdown
    # @see https://developers.notion.com/reference/update-page-markdown
    def update_markdown(page_id:, type:, **params, &block)
        params[:page_id] = page_id
        params[:type] = type
      invoke_operation(:update_markdown, params, &block)
    end
      end
    end
  end
end
