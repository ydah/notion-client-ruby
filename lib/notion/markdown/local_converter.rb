# frozen_string_literal: true

module Notion
  module Markdown
    module LocalConverter
      module_function

      def to_blocks(markdown)
        markdown.lines.filter_map do |line|
          text = line.chomp
          next if text.empty?

          hashes, content = text.match(/\A(\#{1,3})\s+(.*)\z/)&.captures
          type = hashes ? "heading_#{hashes.length}" : "paragraph"
          content ||= text
          { "object" => "block", "type" => type, type => rich_text(content) }
        end
      end

      def to_markdown(blocks)
        blocks.map do |block|
          type = block["type"]
          rich_text = Array(block.dig(type, "rich_text"))
          text = rich_text.map { |item| item["plain_text"] || item.dig("text", "content") }.join
          type.start_with?("heading_") ? "#{'#' * type.delete_prefix('heading_').to_i} #{text}" : text
        end.join("\n\n")
      end

      def rich_text(content)
        { "rich_text" => [{ "type" => "text", "text" => { "content" => content } }] }
      end
    end
  end
end
