# frozen_string_literal: true

require "date"

module Notion
  module Objects
    module PropertySchema
      READ_ONLY = %w[created_by created_time formula last_edited_by last_edited_time rollup unique_id].freeze
      DIRECT = %w[number checkbox url email phone_number].freeze

      module_function

      def convert(properties, schema, strict: false)
        properties.to_h do |name, value|
          definition = schema[name.to_s] || schema[name.to_sym]
          raise Query::UnknownPropertyError, "unknown property: #{name}" if strict && !definition

          [name, definition ? encode(definition.fetch("type", definition[:type]).to_s, value) : value]
        end
      end

      def encode(type, value)
        return value if value.is_a?(Hash)

        validate_writable!(type)
        return { type => value } if DIRECT.include?(type)

        case type
        when "title", "rich_text" then { type => rich_text(value) }
        when "date" then { "date" => { "start" => iso8601(value) } }
        when "select", "status" then { type => value.nil? ? nil : { "name" => value.to_s } }
        when "multi_select" then { type => Array(value).map { |item| { "name" => item.to_s } } }
        when "people", "relation" then { type => references(value) }
        else { type => value }
        end
      end

      def validate_writable!(type)
        raise ValidationError, "#{type} is read-only" if READ_ONLY.include?(type)
      end

      def references(value)
        Array(value).map { |item| { "id" => item.respond_to?(:id) ? item.id : item } }
      end

      def rich_text(value)
        Array(value).map do |item|
          item.is_a?(Hash) ? item : { "type" => "text", "text" => { "content" => item.to_s } }
        end
      end

      def iso8601(value)
        value.respond_to?(:iso8601) ? value.iso8601 : value.to_s
      end
    end
  end
end
