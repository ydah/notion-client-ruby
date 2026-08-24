# frozen_string_literal: true

module Notion
  module Query
    class UnknownPropertyError < Error; end

    class Builder
      DEFAULT_VALUE = Object.new.freeze
      OPERATORS = %i[
        equals does_not_equal contains does_not_contain starts_with ends_with greater_than
        less_than greater_than_or_equal_to less_than_or_equal_to before after on_or_before
        on_or_after is_empty is_not_empty past_week past_month past_year next_week next_month next_year
      ].freeze
      EMPTY_OBJECT_OPERATORS = %i[past_week past_month past_year next_week next_month next_year].freeze

      def initialize(schema: nil, strict: false)
        @filters = []
        @sorts = []
        @schema = schema || {}
        @strict = strict
      end

      def where(property, type: nil)
        Filter.new(self, property, type)
      end

      def add(property, operator, value, type = nil)
        raise ArgumentError, "property is required" if property.nil? || property.to_s.empty?

        definition = @schema[property.to_s] || @schema[property.to_sym]
        raise UnknownPropertyError, "unknown property: #{property}" if @strict && !definition

        property_type = type || schema_type(definition) || :rich_text
        condition = { property: property.to_s, property_type.to_sym => { operator => value } }
        @filters << condition
        self
      end

      def all_of(*filters)
        raise ArgumentError, "all_of requires a filter" if filters.empty?

        @filters << { and: filters.map { |filter| filter_value(filter) } }
        self
      end

      def any_of(*filters)
        raise ArgumentError, "any_of requires a filter" if filters.empty?

        @filters << { or: filters.map { |filter| filter_value(filter) } }
        self
      end

      define_method(:and) do |filter|
        @filters << filter_value(filter) unless filter.equal?(self)
        self
      end

      define_method(:or) do |filter|
        right = filter.equal?(self) ? @filters.pop : filter_value(filter)
        left = @filters.pop || raise(ArgumentError, "or requires a left filter")
        @filters << { or: [left, right] }
        self
      end

      def order(property = nil, timestamp: nil, direction: :ascending)
        raise ArgumentError, "provide either property or timestamp" if property.nil? == timestamp.nil?
        unless %i[ascending descending].include?(direction)
          raise ArgumentError, "direction must be ascending or descending"
        end

        @sorts << { direction: direction }.merge(property ? { property: property.to_s } : { timestamp: timestamp })
        self
      end

      def order_by_timestamp(timestamp, direction = :ascending)
        order(timestamp: timestamp, direction: direction)
      end

      def raw(filter)
        @filters << filter
        self
      end

      def to_h
        result = {}
        result[:filter] = @filters.one? ? @filters.first : { and: @filters } unless @filters.empty?
        result[:sorts] = @sorts unless @sorts.empty?
        result
      end

      private

      def filter_value(filter)
        filter.is_a?(Builder) ? filter.to_h.fetch(:filter) : filter
      end

      def schema_type(definition)
        definition && (definition["type"] || definition[:type])
      end

      class Filter
        def initialize(builder, property, type)
          @builder = builder
          @property = property
          @type = type
        end

        OPERATORS.each do |operator|
          define_method(operator) do |value = DEFAULT_VALUE|
            value = EMPTY_OBJECT_OPERATORS.include?(operator) ? {} : true if value.equal?(DEFAULT_VALUE)
            @builder.add(@property, operator, value, @type)
          end
        end
      end
    end
  end
end
