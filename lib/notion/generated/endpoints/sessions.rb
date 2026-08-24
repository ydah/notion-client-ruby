# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Sessions < Notion::Endpoints::Base
      operation :update, :post, "/v1/sessions", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [["message"], ["session_id", "actions"], ["session_id", "continue_from"]], enums: {}, max_lengths: {} }
      operation :retrieve, :get, "/v1/sessions/{session_id}", path: ["session_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :query, :post, "/v1/sessions/query", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {"query" => 2000} }
      operation :events, :post, "/v1/sessions/{session_id}/events/query", path: ["session_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :cancel, :post, "/v1/sessions/{session_id}/cancel", path: ["session_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }

    # Update a session
    # @see https://developers.notion.com/reference/notion-agent-apis/update-session
    def update(**params, &block)

      invoke_operation(:update, params, &block)
    end
    # Retrieve a session
    # @see https://developers.notion.com/reference/notion-agent-apis/retrieve-session
    def retrieve(session_id:, **params, &block)
        params[:session_id] = session_id
      invoke_operation(:retrieve, params, &block)
    end
    # Query sessions
    # @see https://developers.notion.com/reference/notion-agent-apis/query-sessions
    def query(**params, &block)

      invoke_operation(:query, params, &block)
    end
    # Query session events
    # @see https://developers.notion.com/reference/notion-agent-apis/query-session-events
    def events(session_id:, **params, &block)
        params[:session_id] = session_id
      invoke_operation(:events, params, &block)
    end
    # Cancel a session
    # @see https://developers.notion.com/reference/notion-agent-apis/cancel-session
    def cancel(session_id:, **params, &block)
        params[:session_id] = session_id
      invoke_operation(:cancel, params, &block)
    end
      end
    end
  end
end
