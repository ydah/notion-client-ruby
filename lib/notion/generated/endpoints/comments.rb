# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Comments < Notion::Endpoints::Base
      operation :create, :post, "/v1/comments", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [["parent", "rich_text"], ["parent", "markdown"], ["discussion_id", "rich_text"], ["discussion_id", "markdown"]], enums: {}, max_lengths: {} }
      operation :list, :get, "/v1/comments", path: [], query: ["block_id", "start_cursor", "page_size"], query_rules: { required: ["block_id"], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :retrieve, :get, "/v1/comments/{comment_id}", path: ["comment_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :update, :patch, "/v1/comments/{comment_id}", path: ["comment_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [["rich_text"], ["markdown"]], enums: {}, max_lengths: {} }
      operation :delete, :delete, "/v1/comments/{comment_id}", path: ["comment_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }

    # Create a comment
    # @see https://developers.notion.com/reference/create-a-comment
    def create(**params, &block)

      invoke_operation(:create, params, &block)
    end
    # List comments
    # @see https://developers.notion.com/reference/list-comments
    def list(block_id:, **params, &block)
        params[:block_id] = block_id
      invoke_operation(:list, params, &block)
    end
    # Retrieve a comment
    # @see https://developers.notion.com/reference/retrieve-comment
    def retrieve(comment_id:, **params, &block)
        params[:comment_id] = comment_id
      invoke_operation(:retrieve, params, &block)
    end
    # Update a comment
    # @see https://developers.notion.com/reference/update-a-comment
    def update(comment_id:, **params, &block)
        params[:comment_id] = comment_id
      invoke_operation(:update, params, &block)
    end
    # Delete a comment
    # @see https://developers.notion.com/reference/delete-a-comment
    def delete(comment_id:, **params, &block)
        params[:comment_id] = comment_id
      invoke_operation(:delete, params, &block)
    end
      end
    end
  end
end
