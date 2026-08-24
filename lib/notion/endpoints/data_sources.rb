# frozen_string_literal: true

module Notion
  module Generated
    module Endpoints
      class DataSources
        def query(data_source_id:, **params)
          if block_given?
            builder = Query::Builder.new(
              schema: @client.schema_for(data_source_id),
              strict: @client.config.strict
            )
            yield builder
            params.merge!(builder.to_h)
          end
          params[:data_source_id] = data_source_id
          invoke_operation(:query, params)
        end

        def sync_since(data_source_id:, time:, **params)
          filter = {
            timestamp: "last_edited_time",
            last_edited_time: { on_or_after: time.iso8601 }
          }
          query(data_source_id: data_source_id, **params, filter: filter)
        end
      end
    end
  end
end
