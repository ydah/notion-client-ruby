# frozen_string_literal: true

RSpec.describe Notion::Objects::PropertySchema do
  it "converts Ruby primitives using the data source schema" do
    schema = {
      "Name" => { "type" => "title" },
      "Done" => { "type" => "checkbox" },
      "Due" => { "type" => "date" },
      "Tags" => { "type" => "multi_select" }
    }

    result = described_class.convert(
      { "Name" => "Ship", "Done" => true, "Due" => Date.new(2026, 8, 24), "Tags" => %w[a b] },
      schema,
      strict: true
    )

    expect(result["Name"].dig("title", 0, "text", "content")).to eq("Ship")
    expect(result["Done"]).to eq("checkbox" => true)
    expect(result["Due"]).to eq("date" => { "start" => "2026-08-24" })
    expect(result["Tags"]).to eq("multi_select" => [{ "name" => "a" }, { "name" => "b" }])
  end

  it "covers writable property shapes and preserves raw values" do
    person = Struct.new(:id).new("person")
    schema = {
      "Text" => { "type" => "rich_text" }, "Status" => { "type" => "status" },
      "Select" => { "type" => "select" }, "People" => { "type" => "people" },
      "Relation" => { "type" => "relation" }, "Future" => { "type" => "future" },
      "Raw" => { "type" => "number" }
    }
    raw = { "number" => 1 }
    result = described_class.convert(
      {
        "Text" => ["a", { "type" => "mention" }], "Status" => nil, "Select" => "Open",
        "People" => [person], "Relation" => ["page"], "Future" => "value", "Raw" => raw,
        "Unspecified" => true
      },
      schema
    )

    expect(result["Text"]["rich_text"].length).to eq(2)
    expect(result.values_at("Status", "Select"))
      .to eq([{ "status" => nil }, { "select" => { "name" => "Open" } }])
    expect(result["People"]).to eq("people" => [{ "id" => "person" }])
    expect(result["Relation"]).to eq("relation" => [{ "id" => "page" }])
    expect(result.values_at("Future", "Raw", "Unspecified")).to eq([{ "future" => "value" }, raw, true])
  end

  it "rejects unknown strict and read-only properties" do
    expect { described_class.convert({ Missing: 1 }, {}, strict: true) }
      .to raise_error(Notion::Query::UnknownPropertyError)
    expect { described_class.convert({ Created: Time.now }, { Created: { type: "created_time" } }) }
      .to raise_error(Notion::ValidationError, /read-only/)
  end
end
