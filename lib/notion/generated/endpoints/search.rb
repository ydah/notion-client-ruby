# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class Search < Notion::Endpoints::Base
      operation :search, :post, "/v1/search", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }

    # Search by title
    # @see https://developers.notion.com/reference/post-search
    def search(**params, &block)

      invoke_operation(:search, params, &block)
    end
      end
    end
  end
end
