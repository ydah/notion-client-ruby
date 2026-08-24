# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Blocks < Notion::Endpoints::Base
      operation :retrieve, :get, "/v1/blocks/{block_id}", path: ["block_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :update, :patch, "/v1/blocks/{block_id}", path: ["block_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :delete, :delete, "/v1/blocks/{block_id}", path: ["block_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :children, :get, "/v1/blocks/{block_id}/children", path: ["block_id"], query: ["start_cursor", "page_size"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :append_children, :patch, "/v1/blocks/{block_id}/children", path: ["block_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["children"], variants: [["children"]], enums: {}, max_lengths: {} }

    # Retrieve a block
    # @see https://developers.notion.com/reference/retrieve-a-block
    def retrieve(block_id:, **params, &block)
        params[:block_id] = block_id
      invoke_operation(:retrieve, params, &block)
    end
    # Update a block
    # @see https://developers.notion.com/reference/update-a-block
    def update(block_id:, **params, &block)
        params[:block_id] = block_id
      invoke_operation(:update, params, &block)
    end
    # Delete a block
    # @see https://developers.notion.com/reference/delete-a-block
    def delete(block_id:, **params, &block)
        params[:block_id] = block_id
      invoke_operation(:delete, params, &block)
    end
    # Retrieve block children
    # @see https://developers.notion.com/reference/get-block-children
    def children(block_id:, **params, &block)
        params[:block_id] = block_id
      invoke_operation(:children, params, &block)
    end
    # Append block children
    # @see https://developers.notion.com/reference/patch-block-children
    def append_children(block_id:, children:, **params, &block)
        params[:block_id] = block_id
        params[:children] = children
      invoke_operation(:append_children, params, &block)
    end
      end
    end
  end
end
