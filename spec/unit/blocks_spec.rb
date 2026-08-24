# frozen_string_literal: true

RSpec.describe Notion::Blocks do
  it "builds block payloads with the DSL" do
    blocks = Notion.blocks do
      heading_1 "Design"
      paragraph "Body"
    end

    expect(blocks.map { |block| block["type"] }).to eq(%w[heading_1 paragraph])
    expect(blocks.first.dig("heading_1", "rich_text", 0, "text", "content")).to eq("Design")
  end

  it "applies annotations only to selected text" do
    block = Notion.blocks { paragraph "plain bold plain", bold: ["bold"] }.first
    rich_text = block.dig("paragraph", "rich_text")

    expect(rich_text.map { |item| item.dig("text", "content") }).to eq(["plain ", "bold", " plain"])
    expect(rich_text[1].dig("annotations", "bold")).to be(true)
  end

  it "builds nested, empty, and prebuilt rich text blocks" do
    prebuilt = [{ "type" => "mention", "mention" => { "type" => "user" } }]
    blocks = Notion.blocks do
      toggle "Parent", italic: true do
        paragraph nil
      end
      paragraph prebuilt
    end

    expect(blocks.first.dig("toggle", "children").length).to eq(1)
    expect(blocks.first.dig("toggle", "rich_text", 0, "annotations", "italic")).to be(true)
    expect(blocks.last.dig("paragraph", "rich_text")).to equal(prebuilt)
  end
end

RSpec.describe Notion::Blocks::Chunker do
  it "splits children into API-sized batches" do
    children = Array.new(201) { { "paragraph" => { "rich_text" => [] } } }

    expect(described_class.new(children).chunks.map(&:length)).to eq([100, 100, 1])
  end

  it "splits rich text at 2000 characters" do
    child = Notion.blocks { paragraph "x" * 2001 }.first
    chunks = described_class.new([child]).chunks

    expect(chunks.first.first.dig("paragraph", "rich_text").map { |item| item.dig("text", "content").length })
      .to eq([2000, 1])
  end

  it "splits requests at the nested block limit" do
    children = Array.new(1001) { { "object" => "block", "type" => "divider", "divider" => {} } }

    expect(described_class.new(children).chunks.sum(&:length)).to eq(1001)
  end

  it "can reject oversized rich text" do
    child = Notion.blocks { paragraph "x" * 2001 }.first

    expect { described_class.new([child], on_oversize: :raise) }
      .to raise_error(Notion::ValidationError, /2000/)
  end

  it "validates its policy and rejects unsplittable limits" do
    huge = { "object" => "block", "type" => "code", "code" => { "value" => "x" * 500_001 } }
    nested = {
      "object" => "block", "type" => "toggle",
      "toggle" => { "children" => Array.new(1000) { huge.slice("object") } }
    }

    expect { described_class.new([], on_oversize: :unknown) }.to raise_error(ArgumentError)
    expect { described_class.new([huge]).chunks }.to raise_error(Notion::ValidationError, /500KB/)
    expect { described_class.new([nested]).chunks }.to raise_error(Notion::ValidationError, /1000 block/)
  end
end

RSpec.describe Notion::Generated::Endpoints::Blocks do
  let(:children) { Array.new(201) { { "object" => "block", "type" => "divider", "divider" => {} } } }

  it "uses the explicit position only for the first chunk" do
    responses = %w[first second third].map do |id|
      { "object" => "list", "results" => [{ "object" => "block", "id" => id }], "has_more" => false }
    end
    adapter = Notion::Testing::Adapter.new(*responses)
    client = Notion::Client.new(token: "token", adapter: adapter, rate: 1000)

    ids = client.blocks.append_children(
      block_id: "parent", children: children, position: { type: "start" }
    )
    bodies = adapter.requests.map { |request| JSON.parse(request.body) }

    expect(ids).to eq(%w[first second third])
    expect(bodies.map { |body| body["position"] }).to eq(
      [
        { "type" => "start" },
        { "type" => "after_block", "after_block" => { "id" => "first" } },
        { "type" => "after_block", "after_block" => { "id" => "second" } }
      ]
    )
  end

  it "reports successful IDs after a partial append" do
    first = { "object" => "list", "results" => [{ "object" => "block", "id" => "first" }], "has_more" => false }
    failure = Notion::Transport::Response.new(
      status: 400, headers: {}, body: JSON.generate(code: "validation_error", message: "invalid"),
      request_id: "request", elapsed: 0
    )
    client = Notion::Client.new(
      token: "token", adapter: Notion::Testing::Adapter.new(first, failure), rate: 1000
    )

    expect { client.blocks.append_children(block_id: "parent", children: children) }
      .to raise_error(Notion::PartialAppendError) { |error| expect(error.successful_ids).to eq(["first"]) }
  end
end
