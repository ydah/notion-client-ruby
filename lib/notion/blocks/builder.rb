# frozen_string_literal: true

module Notion
  module Blocks
    class Builder
      ANNOTATIONS = %i[bold italic strikethrough underline code color].freeze

      attr_reader :blocks

      def initialize
        @blocks = []
      end

      def method_missing(type, content = nil, **options, &block)
        children = self.class.build(&block) if block
        annotations = options.slice(*ANNOTATIONS)
        payload = options.except(*ANNOTATIONS).merge("rich_text" => rich_text(content, annotations))
        payload["children"] = children if children
        @blocks << { "object" => "block", "type" => type.to_s, type.to_s => payload.compact }
        self
      end

      def respond_to_missing?(_name, _include_private = false) = true

      def self.build(&)
        builder = new
        builder.instance_eval(&)
        builder.blocks
      end

      private

      def rich_text(content, annotations)
        return content if content.is_a?(Array)
        return [] if content.nil?

        segments(content.to_s, annotations).map do |segment|
          item = { "type" => "text", "text" => { "content" => segment } }
          item["annotations"] = annotation_values(segment, annotations) unless annotations.empty?
          item
        end
      end

      def segments(text, annotations)
        marked = annotations.values.grep(Array).flatten.map(&:to_s)
        marked.empty? ? [text] : text.split(/(#{Regexp.union(marked)})/).reject(&:empty?)
      end

      def annotation_values(segment, annotations)
        annotations.to_h do |name, value|
          enabled = value.is_a?(Array) ? value.map(&:to_s).include?(segment) : value
          [name.to_s, enabled]
        end
      end
    end
  end
end
