# frozen_string_literal: true

require "tmpdir"
require_relative "../../codegen/generator"

RSpec.describe Generator do
  let(:openapi) do
    {
      "paths" => {
        "/v1/widgets" => {
          "post" => {
            "operationId" => "create-widget",
            "tags" => ["Widgets"],
            "requestBody" => { "$ref" => "#/components/requestBodies/CreateWidget" }
          }
        }
      },
      "components" => {
        "requestBodies" => {
          "CreateWidget" => {
            "required" => true,
            "content" => { "application/json" => { "schema" => { "$ref" => "#/components/schemas/Widget" } } }
          }
        },
        "schemas" => {
          "Widget" => {
            "required" => ["name"],
            "properties" => {
              "name" => { "type" => "string", "maxLength" => 10 },
              "kind" => { "type" => "string", "enum" => %w[a b] }
            },
            "allOf" => [{ "$ref" => "#/components/schemas/Parent" }],
            "oneOf" => [
              { "required" => %w[common first] },
              { "required" => %w[common second] }
            ]
          },
          "Parent" => { "required" => ["parent"] }
        }
      }
    }
  end

  it "resolves referenced request bodies and nested required properties" do
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "codegen"))
      File.write(File.join(root, "codegen/naming.yml"), "{}\n")
      File.write(File.join(root, "codegen/overrides.yml"), "{}\n")
      File.write(File.join(root, "codegen/openapi.json"), JSON.generate(openapi))

      operation = described_class.new(root: root).operations.first

      expect(operation).to include(
        body_required: true,
        required_body_params: %w[name parent common],
        body_requirement_variants: [%w[name parent common first], %w[name parent common second]],
        body_enums: { "kind" => %w[a b] },
        body_max_lengths: { "name" => 10 }
      )

      described_class.new(root: root).generate
      generated = File.read(File.join(root, "lib/notion/generated/endpoints/widgets.rb"))
      expect(generated).to include('enums: {"kind" => ["a", "b"]}, max_lengths: {"name" => 10}')
    end
  end
end
