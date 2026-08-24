# frozen_string_literal: true

module Notion
  module Objects
    class Page < Base
      def [](key)
        property = raw.fetch("properties", {})[key.to_s]
        property ? PropertyValue.build(property) : super
      end

      def title
        title_property = raw.fetch("properties", {}).values.find { |property| property["type"] == "title" }
        title_property && PropertyValue.build(title_property).to_s
      end

      def parent = Parent.new(raw.fetch("parent", {}))
      def icon = raw["icon"] && Icon.new(raw["icon"])
    end

    class Database < Base; end
    class DataSource < Base; end

    class Block < Base
      TYPES = %w[
        audio bookmark breadcrumb bulleted_list_item callout child_database child_page code
        column column_list divider embed equation file heading_1 heading_2 heading_3 image
        link_preview link_to_page meeting_notes numbered_list_item paragraph pdf quote
        synced_block table table_of_contents table_row template todo toggle transcription video
      ].freeze

      def self.build(raw)
        name = raw["type"].to_s.split("_").map(&:capitalize).join
        return new(raw) if name.empty?

        klass = const_defined?(name, false) ? const_get(name, false) : self
        klass.new(raw)
      end

      TYPES.each { |type| const_set(type.split("_").map(&:capitalize).join, Class.new(self)) }
    end

    class User < Base; end
    class Comment < Base; end
    class View < Base; end
    class File < Base; end
    class Parent < Base; end
    class Icon < Base; end
    class AsyncTask < Base; end

    class RichText < Base
      def to_s
        raw["plain_text"] || raw.dig("text", "content").to_s
      end
    end
  end
end
