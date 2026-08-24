# frozen_string_literal: true

module Notion
  module Generated
    module Endpoints
      class Pages
        def create(parent:, **params)
          params[:parent] = parent
          properties = params[:properties]
          parent, data_source_id = normalize_parent(parent)
          params[:parent] = parent unless parent.empty?
          params[:properties] = convert(properties, data_source_id) if properties && data_source_id
          invoke_operation(:create, params)
        end

        def update(page_id:, **params)
          if primitive?(params[:properties])
            page = retrieve(page_id: page_id)
            parent = page.raw.fetch("parent", {})
            data_source_id = parent["data_source_id"] || parent["database_id"]
            params[:properties] = convert(params[:properties], data_source_id)
          end
          params[:page_id] = page_id
          invoke_operation(:update, params)
        end

        private

        def normalize_parent(parent)
          data_source_id = parent[:data_source_id] || parent["data_source_id"]
          database_id = parent[:database_id] || parent["database_id"]
          return [parent, data_source_id] if data_source_id || !database_id
          return [parent, database_id] if @client.config.notion_version == "2022-06-28"

          data_source_id = @client.resolve_data_source(database_id: database_id)
          normalized = parent.except(:database_id, "database_id").merge(data_source_id: data_source_id)
          [normalized, data_source_id]
        end

        def primitive?(properties)
          properties&.any? { |_name, value| !value.is_a?(Hash) }
        end

        def convert(properties, data_source_id)
          return properties unless data_source_id

          Objects::PropertySchema.convert(
            properties,
            @client.schema_for(data_source_id),
            strict: @client.config.strict
          )
        end
      end
    end
  end
end
