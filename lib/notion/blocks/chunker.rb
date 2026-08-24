# frozen_string_literal: true

require "json"

module Notion
  module Blocks
    class Chunker
      MAX_CHILDREN = 100
      MAX_BYTES = 500_000
      MAX_BLOCKS = 1000

      def initialize(children, on_oversize: :split)
        raise ArgumentError, "on_oversize must be :split or :raise" unless %i[split raise].include?(on_oversize)

        @on_oversize = on_oversize
        @children = transform(children)
      end

      def chunks
        @children.each_with_object([[]]) do |child, groups|
          raise ValidationError, "a block exceeds the 500KB request limit" if bytes([child]) > MAX_BYTES
          raise ValidationError, "a block tree exceeds the 1000 block limit" if block_count(child) > MAX_BLOCKS

          groups << [] if full?(groups.last, child)
          groups.last << child
        end.reject(&:empty?)
      end

      private

      def bytes(children)
        JSON.generate(children: children).bytesize
      end

      def full?(group, child)
        group.length >= MAX_CHILDREN || bytes(group + [child]) > MAX_BYTES ||
          block_count(group) + block_count(child) > MAX_BLOCKS
      end

      def transform(value)
        case value
        when Hash then value.to_h { |key, item| [key, transform(item)] }
        when Array then value.flat_map { |item| rich_text_item?(item) ? split_item(item) : [transform(item)] }
        else value
        end
      end

      def rich_text_item?(value)
        value.is_a?(Hash) && value.dig("text", "content").is_a?(String)
      end

      def split_item(item)
        text = item.dig("text", "content")
        raise ValidationError, "rich text exceeds 2000 characters" if @on_oversize == :raise && text.length > 2000

        text.scan(/.{1,2000}/m).map do |content|
          transform(item.merge("text" => item.fetch("text").merge("content" => content)))
        end
      end

      def block_count(value)
        case value
        when Hash then (value["object"] == "block" ? 1 : 0) + value.values.sum { |item| block_count(item) }
        when Array then value.sum { |item| block_count(item) }
        else 0
        end
      end
    end
  end
end
