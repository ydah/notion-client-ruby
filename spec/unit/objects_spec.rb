# frozen_string_literal: true

RSpec.describe Notion::ObjectFactory do
  it "keeps unknown fields and normalizes legacy trash state" do
    page = described_class.build(
      "object" => "page",
      "id" => "abc",
      "archived" => true,
      "future_field" => { "enabled" => true }
    )

    expect(page).to be_a(Notion::Objects::Page)
    expect(page.in_trash?).to be(true)
    expect(page.future_field).to eq("enabled" => true)
    expect(page.deconstruct_keys([:id])).to eq(id: "abc")
  end

  it "wraps page properties and renders titles" do
    page = described_class.build(
      "object" => "page",
      "properties" => {
        "Name" => {
          "type" => "title",
          "title" => [{ "plain_text" => "Roadmap" }]
        }
      }
    )

    expect(page["Name"]).to be_a(Notion::Objects::PropertyValue::Title)
    expect(page["Name"].to_s).to eq("Roadmap")
    expect(page.title).to eq("Roadmap")
  end

  it "delegates typed property access and deeply freezes raw responses" do
    property = described_class.build(
      "type" => "date", "date" => { "start" => "2026-08-24", "end" => nil }
    )

    expect(property.start).to eq("2026-08-24")
    expect(property.respond_to?(:start)).to be(true)
    expect(property.end?).to be(false)
    expect(property.raw.fetch("date")).to be_frozen
  end

  it "preserves unknown object types" do
    object = described_class.build("object" => "future_object", "new_field" => 1)

    expect(object).to be_a(Notion::Objects::Unknown)
    expect(object["new_field"]).to eq(1)
  end

  it "preserves malformed blocks without a type" do
    block = described_class.build("object" => "block", "id" => "block")

    expect(block).to be_a(Notion::Objects::Block)
    expect(block.id).to eq("block")
  end

  it "uses typed blocks and nested page values" do
    block = described_class.build("object" => "block", "type" => "paragraph", "paragraph" => {})
    page = described_class.build(
      "object" => "page", "parent" => { "type" => "workspace" }, "icon" => { "type" => "emoji" }
    )

    expect(block).to be_a(Notion::Objects::Block::Paragraph)
    expect(page.parent).to be_a(Notion::Objects::Parent)
    expect(page.icon).to be_a(Notion::Objects::Icon)
  end

  it "renders property values and falls back for unknown block types" do
    select = Notion::Objects::PropertyValue.build("type" => "select", "select" => nil)
    multi = Notion::Objects::PropertyValue.build(
      "type" => "multi_select", "multi_select" => [{ "name" => "A" }, {}]
    )
    number = Notion::Objects::PropertyValue.build("type" => "number", "number" => 3)
    future = Notion::Objects::PropertyValue.build("type" => "future", "future" => "x")
    block = described_class.build("object" => "block", "type" => "future_block")

    expect([select.to_s, multi.to_s, number.to_s, future.to_s]).to eq(["", "A", "3", "x"])
    expect(block.class).to eq(Notion::Objects::Block)
  end

  it "supports dynamic access, predicates, and pattern matching all keys" do
    object = Notion::Objects::Unknown.new("id" => "id", "enabled" => 1)

    expect(object.enabled?).to be(true)
    expect(object.respond_to?(:enabled)).to be(true)
    expect(object.respond_to?(:missing)).to be(false)
    expect(object.deconstruct_keys(nil)).to eq(id: "id", enabled: 1)
    expect { object.missing }.to raise_error(NoMethodError)
  end

  it "wraps plain hashes, arrays, and scalars" do
    value = described_class.wrap_value(
      "page" => { "object" => "page", "id" => "id" }, "items" => [{ "object" => "future" }, 1]
    )

    expect(value["page"]).to be_a(Notion::Objects::Page)
    expect(value["items"].first).to be_a(Notion::Objects::Unknown)
    expect(value["items"].last).to eq(1)
    expect(described_class.build(2)).to eq(2)
  end
end

RSpec.describe Notion::ID do
  it "normalizes compact UUIDs" do
    expect(described_class.normalize("248104cd477e80fdb757e945d38000bd"))
      .to eq("248104cd-477e-80fd-b757-e945d38000bd")
  end
end
