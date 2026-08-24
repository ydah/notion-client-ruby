# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

RSpec.describe "generated endpoint coverage" do
  it "covers every OpenAPI operation" do
    count = Notion::Generated::RESOURCES.values.sum { |endpoint| endpoint.operations.length }

    expect(count).to eq(61)
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
