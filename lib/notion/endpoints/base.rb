# frozen_string_literal: true

require "uri"

module Notion
  module Endpoints
    class Base
      class << self
        def operations
          @operations ||= {}
        end

        def operation(name, verb, template, path:, query:, query_rules:, body_rules:)
          operations[name] = {
            verb: verb,
            path: template,
            path_params: path,
            query_params: query,
            query_rules: query_rules,
            body_rules: body_rules
          }
        end
      end

      def initialize(client)
        @client = client
      end

      private

      def invoke_operation(name, params)
        if block_given?
          builder = Query::Builder.new
          yield builder
          params = params.merge(builder.to_h)
        end
        operation = self.class.operations.fetch(name)
        perform(
          name,
          operation[:verb],
          operation[:path],
          params,
          path: operation[:path_params],
          query: operation[:query_params],
          rules: operation.slice(:query_rules, :body_rules)
        )
      end

      def perform(name, verb, template, params, path:, query:, rules: {})
        original_params = params.dup
        request_path = path.reduce(template) { |value, key| value.sub("{#{key}}", escape(params.delete(key.to_sym))) }
        validate_query!(params, rules.fetch(:query_rules, {}))
        request_query = params.slice(*query.map(&:to_sym))
        request_body = prepare_body(params.except(*query.map(&:to_sym)), rules.fetch(:body_rules, {}))
        result = @client.request(verb, request_path, query: request_query, body: request_body)
        return result unless result.is_a?(Objects::List)

        result.with_fetcher { |cursor| public_send(name, **original_params, start_cursor: cursor) }
      end

      def prepare_body(body, rules)
        missing = Array(rules[:required]).reject { |key| body.key?(key.to_sym) }
        raise ArgumentError, "required body parameters are missing: #{missing.join(', ')}" unless missing.empty?

        validate_body_variants!(body, rules[:variants])
        validate_constraints!(body, rules)
        body.empty? && !rules[:send_empty] ? nil : body
      end

      def validate_body_variants!(body, variants)
        variants = Array(variants)
        return if variants.empty? || variants.any? { |keys| keys.all? { |key| body.key?(key.to_sym) } }

        expected = variants.map { |keys| keys.join(" + ") }.join(" or ")
        raise ArgumentError, "body must include #{expected}"
      end

      def validate_query!(params, rules)
        missing = Array(rules[:required]).reject { |key| params.key?(key.to_sym) }
        raise ArgumentError, "required query parameters are missing: #{missing.join(', ')}" unless missing.empty?

        validate_constraints!(params, rules)
      end

      def validate_constraints!(params, rules)
        rules.fetch(:enums, {}).each do |key, values|
          value = params[key.to_sym]
          next if value.nil? || values.include?(value.to_s)

          raise ArgumentError, "#{key} must be one of: #{values.join(', ')}"
        end
        rules.fetch(:max_lengths, {}).each do |key, length|
          value = params[key.to_sym]
          next unless value.respond_to?(:length) && value.length > length

          raise ArgumentError, "#{key} exceeds #{length} characters"
        end
      end

      def escape(value)
        raise ArgumentError, "required path parameter is missing" if value.nil? || value.to_s.empty?

        URI.encode_uri_component(value.to_s)
      end
    end
  end
end
