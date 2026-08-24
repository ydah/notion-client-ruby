# frozen_string_literal: true

require "notion"

module Notion
  class Client
    alias modern_search search

    def database_query(database_id:, **params, &)
      deprecate(:database_query, "query")
      query(database_id, **params, &)
    end

    def database(database_id:)
      deprecate(:database, "databases.retrieve")
      databases.retrieve(database_id: database_id)
    end

    def page(page_id:)
      deprecate(:page, "pages.retrieve")
      pages.retrieve(page_id: page_id)
    end

    def create_page(**params)
      deprecate(:create_page, "pages.create")
      pages.create(**params)
    end

    def block_children(block_id:, **params)
      deprecate(:block_children, "blocks.children")
      blocks.children(block_id: block_id, **params)
    end

    def search(**params, &block)
      result = modern_search(**params)
      return result unless block

      result.each_result(&block)
    end

    private

    def deprecate(old_name, replacement)
      warn "Notion::Client##{old_name} is deprecated; use #{replacement}", uplevel: 2
    end
  end
end
