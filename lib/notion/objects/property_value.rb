# frozen_string_literal: true

module Notion
  module Objects
    class PropertyValue < Base
      TYPES = %w[
        button checkbox created_by created_time date email files formula last_edited_by
        last_edited_time multi_select number people phone_number place relation rich_text
        rollup select status title unique_id url verification
      ].freeze

      def value
        raw[raw["type"]]
      end

      def to_s
        case raw["type"]
        when "title", "rich_text"
          Array(value).map { |item| item["plain_text"] || item.dig("text", "content") }.join
        when "select", "status" then value&.fetch("name", "").to_s
        when "multi_select" then Array(value).filter_map { |item| item["name"] }.join(", ")
        else value.to_s
        end
      end

      def respond_to_missing?(name, include_private = false)
        (value.is_a?(Hash) && value.key?(attribute_name(name))) || super
      end

      def method_missing(name, *args)
        key = attribute_name(name)
        return super unless args.empty? && value.is_a?(Hash) && value.key?(key)

        name.end_with?("?") ? !!value[key] : ObjectFactory.wrap_value(value[key])
      end

      def attribute_name(name)
        name.to_s.delete_suffix("?")
      end

      def self.build(raw)
        type = raw["type"].to_s
        klass = const_defined?(class_name(type), false) ? const_get(class_name(type), false) : self
        klass.new(raw)
      end

      def self.class_name(type)
        type.split("_").map(&:capitalize).join
      end

      TYPES.each { |type| const_set(class_name(type), Class.new(self)) }

      private :attribute_name
    end
  end
end
