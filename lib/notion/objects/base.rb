# frozen_string_literal: true

module Notion
  module Objects
    class Base
      attr_reader :raw

      def initialize(raw)
        @raw = deep_freeze(raw)
      end

      def [](key)
        value_for(key.to_s)
      end

      def deconstruct_keys(keys)
        selected = keys || raw.keys
        selected.to_h { |key| [key.to_sym, value_for(key.to_s)] }
      end

      def in_trash?
        !!(raw["in_trash"] || raw["archived"])
      end

      def inspect
        attributes = %w[object id type].filter_map { |key| "#{key}=#{raw[key].inspect}" if raw.key?(key) }
        "#<#{self.class} #{attributes.join(' ')}>"
      end

      def respond_to_missing?(name, include_private = false)
        raw.key?(attribute_name(name)) || super
      end

      def method_missing(name, *args)
        key = attribute_name(name)
        return super unless args.empty? && raw.key?(key)

        name.end_with?("?") ? !!raw[key] : value_for(key)
      end

      private

      def deep_freeze(value)
        case value
        when Hash then value.each_value { |item| deep_freeze(item) }
        when Array then value.each { |item| deep_freeze(item) }
        end
        value.freeze
      end

      def attribute_name(name)
        name.to_s.delete_suffix("?")
      end

      def value_for(key)
        ObjectFactory.wrap_value(raw[key])
      end
    end

    class Unknown < Base; end
  end
end
