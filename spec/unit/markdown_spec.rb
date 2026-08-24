# frozen_string_literal: true

RSpec.describe Notion::Markdown::LocalConverter do
  it "converts headings and paragraphs in both directions" do
    blocks = described_class.to_blocks("# Title\n\nBody\n")

    expect(blocks.map { |block| block["type"] }).to eq(%w[heading_1 paragraph])
    expect(described_class.to_markdown(blocks)).to eq("# Title\n\nBody")
  end
end
