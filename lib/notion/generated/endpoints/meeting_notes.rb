# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class MeetingNotes < Notion::Endpoints::Base
      operation :create, :post, "/v1/blocks/meeting_notes", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["source"], variants: [["source", "parent"], ["source"]], enums: {"language" => ["auto", "en", "zh-CN", "zh-TW", "es", "fr", "de", "ja", "ko", "pt", "ru", "th", "vi", "id", "da", "fi", "no", "nl", "it", "sv", "ar", "he", "pl"]}, max_lengths: {"title" => 2000} }
      operation :query, :post, "/v1/blocks/meeting_notes/query", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {}, max_lengths: {} }

    # Create a meeting note
    # @see https://developers.notion.com/reference/create-meeting-note
    def create(source:, **params, &block)
        params[:source] = source
      invoke_operation(:create, params, &block)
    end
    # Query meeting notes
    # @see https://developers.notion.com/reference/query-meeting-notes
    def query(**params, &block)

      invoke_operation(:query, params, &block)
    end
      end
    end
  end
end
