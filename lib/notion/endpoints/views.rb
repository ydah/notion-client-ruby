# frozen_string_literal: true

module Notion
  module Generated
    module Endpoints
      class Views
        def with_query(view_id:, **params)
          query = create_query(view_id: view_id, **params)
          yield query_results(view_id: view_id, query_id: query.id)
        ensure
          delete_query(view_id: view_id, query_id: query.id) if query.respond_to?(:id)
        end
      end
    end
  end
end
