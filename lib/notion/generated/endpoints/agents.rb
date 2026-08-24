# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Agents < Notion::Endpoints::Base
      operation :query, :post, "/v1/agents/query", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :retrieve, :get, "/v1/agents/{agent_id}", path: ["agent_id"], query: ["verbose"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :delete, :delete, "/v1/agents/{agent_id}", path: ["agent_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :insights, :get, "/v1/agents/{agent_id}/insights", path: ["agent_id"], query: ["start_time", "end_time"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :update_status, :patch, "/v1/agents/{agent_id}/status", path: ["agent_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["status"], variants: [["status"]], enums: {"status" => ["active", "disabled"]}, max_lengths: {} }
      operation :update_credit_limit, :patch, "/v1/agents/{agent_id}/credit_limit", path: ["agent_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["credit_limit"], variants: [["credit_limit"]], enums: {}, max_lengths: {} }
      operation :batch, :post, "/v1/agents/batch", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["operations"], variants: [["operations"]], enums: {}, max_lengths: {} }

    # Query agents
    # @see https://developers.notion.com/reference/notion-agent-apis/query-agents
    def query(**params, &block)

      invoke_operation(:query, params, &block)
    end
    # Get agent
    # @see https://developers.notion.com/reference/notion-agent-apis/retrieve-agent
    def retrieve(agent_id:, **params, &block)
        params[:agent_id] = agent_id
      invoke_operation(:retrieve, params, &block)
    end
    # Delete agent
    # @see https://developers.notion.com/reference/notion-agent-apis/delete-agent
    def delete(agent_id:, **params, &block)
        params[:agent_id] = agent_id
      invoke_operation(:delete, params, &block)
    end
    # Get agent insights
    # @see https://developers.notion.com/reference/notion-agent-apis/retrieve-agent-insights
    def insights(agent_id:, **params, &block)
        params[:agent_id] = agent_id
      invoke_operation(:insights, params, &block)
    end
    # Update agent status
    # @see https://developers.notion.com/reference/notion-agent-apis/update-agent-status
    def update_status(agent_id:, status:, **params, &block)
        params[:agent_id] = agent_id
        params[:status] = status
      invoke_operation(:update_status, params, &block)
    end
    # Update agent credit limit
    # @see https://developers.notion.com/reference/notion-agent-apis/update-agent-credit-limit
    def update_credit_limit(agent_id:, credit_limit:, **params, &block)
        params[:agent_id] = agent_id
        params[:credit_limit] = credit_limit
      invoke_operation(:update_credit_limit, params, &block)
    end
    # Apply many agent operations
    # @see https://developers.notion.com/reference/notion-agent-apis/batch-manage-agent
    def batch(operations:, **params, &block)
        params[:operations] = operations
      invoke_operation(:batch, params, &block)
    end
      end
    end
  end
end
