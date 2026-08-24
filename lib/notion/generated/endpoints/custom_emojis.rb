# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class CustomEmojis < Notion::Endpoints::Base
      operation :list, :get, "/v1/custom_emojis", path: [], query: ["start_cursor", "page_size", "name"], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }

    # List custom emojis
    # @see https://developers.notion.com/reference/list-custom-emojis
    def list(**params, &block)

      invoke_operation(:list, params, &block)
    end
      end
    end
  end
end
