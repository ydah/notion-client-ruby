# frozen_string_literal: true

module Notion
  module Generated
    module Endpoints
      class Blocks
        def append_children(block_id:, children:, position: nil, after: nil, on_oversize: :split, **params)
          successful_ids = []
          Notion::Blocks::Chunker.new(children, on_oversize: on_oversize).chunks.each_with_index do |chunk, index|
            placement = if index.zero?
                          position || after_position(after)
                        else
                          after_position(successful_ids.last)
                        end
            response = perform(
              :append_children,
              :patch,
              "/v1/blocks/{block_id}/children",
              params.merge(block_id: block_id, children: chunk, position: placement).compact,
              path: ["block_id"],
              query: [],
              rules: { body_rules: { send_empty: true, required: ["children"] } }
            )
            successful_ids.concat(response.results.filter_map(&:id)) if response.respond_to?(:results)
          end
          successful_ids
        rescue Error => e
          raise PartialAppendError.new(e.message, successful_ids: successful_ids, cause: e)
        end

        private

        def after_position(id)
          id && { type: "after_block", after_block: { id: id } }
        end
      end
    end
  end
end
