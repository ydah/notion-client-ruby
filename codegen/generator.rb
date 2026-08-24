# frozen_string_literal: true

require "json"
require "yaml"
require "fileutils"

class Generator
  HTTP_METHODS = %w[get post patch delete put].freeze

  def initialize(root: File.expand_path("..", __dir__))
    @root = root
    @spec = JSON.parse(File.read(File.join(@root, "codegen/openapi.json")))
    @names = YAML.safe_load_file(File.join(@root, "codegen/naming.yml")) || {}
    @overrides = YAML.safe_load_file(File.join(@root, "codegen/overrides.yml")) || {}
  end

  def generate
    operations.group_by { |operation| operation[:resource] }.each do |resource, items|
      write("lib/notion/generated/endpoints/#{resource}.rb", endpoint_source(resource, items))
    end
    write("lib/notion/generated.rb", registry_source)
    write("spec/generated/endpoint_coverage_spec.rb", coverage_spec_source)
  end

  def operations
    @operations ||= @spec.fetch("paths").flat_map do |path, path_item|
      path_item.filter_map do |verb, operation|
        build_operation(path, verb, operation, path_item) if HTTP_METHODS.include?(verb)
      end
    end
  end

  private

  def build_operation(path, verb, operation, path_item)
    operation_id = operation.fetch("operationId")
    parameters = (Array(path_item["parameters"]) + Array(operation["parameters"])).map { |item| resolve(item) }
    item = {
      operation_id: operation_id,
      name: @names.fetch(operation_id, operation_id.tr("-", "_")),
      resource: resource_name(Array(operation["tags"]).first),
      verb: verb,
      path: path,
      path_params: path.scan(/\{([^}]+)\}/).flatten,
      body_required: request_body(operation)["required"] == true,
      required_body_params: required_body_params(operation),
      body_requirement_variants: body_requirement_variants(operation),
      summary: operation["summary"],
      reference: operation["x-notion-docs-ref"]
    }
    item.merge(query_details(parameters), body_details(operation), symbolize(@overrides.fetch(operation_id, {})))
  end

  def query_details(parameters)
    parameters = parameters.select { |parameter| parameter["in"] == "query" }
    schemas = parameters.to_h { |parameter| [parameter["name"], parameter["schema"] || {}] }
    {
      query_params: parameters.map { |parameter| parameter["name"] },
      required_query_params: parameters.filter_map { |parameter| parameter["name"] if parameter["required"] },
      query_enums: constraints(schemas, "enum"),
      query_max_lengths: constraints(schemas, "maxLength")
    }
  end

  def body_details(operation)
    schema = request_body(operation).dig("content", "application/json", "schema") || {}
    properties = top_level_properties(schema)
    {
      body_enums: constraints(properties, "enum"),
      body_max_lengths: constraints(properties, "maxLength")
    }
  end

  def constraints(schemas, keyword)
    schemas.filter_map do |key, schema|
      constraint = resolve(schema)[keyword]
      [key, constraint] if constraint
    end.to_h
  end

  def top_level_properties(schema)
    schema = resolve(schema)
    Array(schema["allOf"]).reduce(schema.fetch("properties", {})) do |properties, item|
      properties.merge(top_level_properties(item))
    end
  end

  def resolve(item)
    return item unless item["$ref"]

    item["$ref"].delete_prefix("#/").split("/").reduce(@spec) { |value, key| value.fetch(key) }
  end

  def required_body_params(operation)
    body_requirement_variants(operation).reduce(:&).to_a
  end

  def body_requirement_variants(operation)
    schema = request_body(operation).dig("content", "application/json", "schema") || {}
    variants = requirement_variants(schema).map(&:uniq).uniq
    variants.any?(&:empty?) ? [] : variants
  end

  def request_body(operation)
    resolve(operation["requestBody"] || {})
  end

  def requirement_variants(schema)
    schema = resolve(schema)
    variants = [Array(schema["required"])]
    Array(schema["allOf"]).each { |item| variants = combine(variants, requirement_variants(item)) }
    alternatives = Array(schema["oneOf"] || schema["anyOf"]).flat_map { |item| requirement_variants(item) }
    alternatives.empty? ? variants : combine(variants, alternatives)
  end

  def combine(left, right)
    left.product(right).map { |first, second| first + second }
  end

  def symbolize(hash)
    hash.to_h { |key, value| [key.to_sym, value] }
  end

  def resource_name(tag)
    tag.to_s.downcase.tr(" ", "_")
  end

  def class_name(resource)
    resource.split("_").map(&:capitalize).join
  end

  def endpoint_source(resource, items)
    declarations = items.map { |item| operation_declaration(item) }.join("\n")
    methods = items.map { |item| endpoint_method_source(item) }.join("\n")
    <<~RUBY
      # frozen_string_literal: true

      # This file is generated. DO NOT EDIT.

      module Notion
        module Generated
          module Endpoints
            class #{class_name(resource)} < Notion::Endpoints::Base
      #{declarations}

      #{methods}
            end
          end
        end
      end
    RUBY
  end

  def operation_declaration(item)
    %(      operation :#{item[:name]}, :#{item[:verb]}, #{item[:path].inspect}, ) +
      "path: #{item[:path_params].inspect}, query: #{item[:query_params].inspect}, " \
      "query_rules: { required: #{item[:required_query_params].inspect}, enums: #{hash_literal(item[:query_enums])}, " \
      "max_lengths: #{hash_literal(item[:query_max_lengths])} }, " \
      "body_rules: { send_empty: #{item[:body_required]}, required: #{item[:required_body_params].inspect}, " \
      "variants: #{item[:body_requirement_variants].inspect}, enums: #{hash_literal(item[:body_enums])}, " \
      "max_lengths: #{hash_literal(item[:body_max_lengths])} }"
  end

  def hash_literal(hash)
    "{#{hash.map { |key, value| "#{key.inspect} => #{value.inspect}" }.join(", ")}}"
  end

  def endpoint_method_source(item)
    required_names = (item[:path_params] + item[:required_query_params] + item[:required_body_params]).uniq
    required = required_names.map { |name| "#{name}:" }
    arguments = (required + ["**params", "&block"]).join(", ")
    assignments = required_names.map { |name| "        params[:#{name}] = #{name}" }.join("\n")
    <<~RUBY.chomp
          # #{item[:summary]}
          # @see #{item[:reference]}
          def #{item[:name]}(#{arguments})
      #{assignments}
            invoke_operation(:#{item[:name]}, params, &block)
          end
    RUBY
  end

  def registry_source
    resources = operations.map { |operation| operation[:resource] }.uniq.sort
    requires = resources.map { |resource| %(require_relative "generated/endpoints/#{resource}") }.join("\n")
    entries = resources.map do |resource|
      "      #{resource}: Endpoints::#{class_name(resource)}"
    end.join(",\n")
    <<~RUBY
      # frozen_string_literal: true

      # This file is generated. DO NOT EDIT.

      #{requires}

      module Notion
        module Generated
          RESOURCES = {
      #{entries}
          }.freeze
        end
      end
    RUBY
  end

  def coverage_spec_source
    count = operations.length
    <<~RUBY
      # frozen_string_literal: true

      # This file is generated. DO NOT EDIT.

      RSpec.describe "generated endpoint coverage" do
        it "covers every OpenAPI operation" do
          count = Notion::Generated::RESOURCES.values.sum { |endpoint| endpoint.operations.length }

          expect(count).to eq(#{count})
        end

        it "exposes required path keywords and sends every HTTP shape" do
          client = Class.new do
            attr_reader :last_request

            def request(*args, **kwargs)
              @last_request = [args, kwargs]
              {}
            end
          end.new

          Notion::Generated::RESOURCES.each_value do |endpoint_class|
            endpoint = endpoint_class.new(client)
            endpoint_class.operations.each do |name, operation|
              params = operation[:path_params].to_h { |key| [key.to_sym, "value"] }
              params.merge!(operation[:query_params].to_h { |key| [key.to_sym, "query"] })
              operation[:query_rules][:enums].each { |key, values| params[key.to_sym] = values.first }
              operation[:body_rules][:required].each do |key|
                params[key.to_sym] = case key
                                     when "children" then [{}]
                                     when "parent" then { page_id: "value" }
                                     else "value"
                                     end
              end
              operation[:body_rules][:variants].first.to_a.each do |key|
                params[key.to_sym] ||= key == "parent" ? { page_id: "value" } : "value"
              end
              operation[:body_rules][:enums].each { |key, values| params[key.to_sym] = values.first }
              endpoint.method(name).parameters.each do |kind, key|
                next unless kind == :keyreq

                params[key] ||= key == :children ? [{}] : "value"
                params[key] = { page_id: "value" } if key == :parent
              end
              endpoint.public_send(name, **params)

              expected_path = operation[:path_params].reduce(operation[:path]) do |path, key|
                path.sub("{" + key + "}", "value")
              end
              expect(client.last_request.first).to eq([operation[:verb], expected_path])
              required = operation[:path_params] + operation[:query_rules][:required] + operation[:body_rules][:required]
              required.each do |key|
                expect(endpoint.method(name).parameters).to include([:keyreq, key.to_sym])
              end
            end
          end
        end
      end
    RUBY
  end

  def write(path, content)
    absolute = File.join(@root, path)
    FileUtils.mkdir_p(File.dirname(absolute))
    File.write(absolute, content)
  end
end

Generator.new.generate if $PROGRAM_NAME == __FILE__
