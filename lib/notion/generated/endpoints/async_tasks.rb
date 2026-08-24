# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class AsyncTasks < Notion::Endpoints::Base
      operation :retrieve, :get, "/v1/async_tasks/{task_id}", path: ["task_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }

    # Retrieve an async task
    # @see https://developers.notion.com/reference/retrieve-async-task
    def retrieve(task_id:, **params, &block)
        params[:task_id] = task_id
      invoke_operation(:retrieve, params, &block)
    end
      end
    end
  end
end
