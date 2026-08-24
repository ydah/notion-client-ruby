# frozen_string_literal: true

module Notion
  module ObjectFactory
    TYPES = {
      "page" => Objects::Page,
      "database" => Objects::Database,
      "data_source" => Objects::DataSource,
      "block" => Objects::Block,
      "user" => Objects::User,
      "comment" => Objects::Comment,
      "view" => Objects::View,
      "file_upload" => Objects::File,
      "async_task" => Objects::AsyncTask,
      "list" => Objects::List
    }.freeze

    module_function

    def build(value)
      return wrap_value(value) unless value.is_a?(Hash)
      if !value.key?("object") && value.key?("type") && value.key?(value["type"])
        return Objects::PropertyValue.build(value)
      end
      return Objects::Block.build(value) if value["object"] == "block"

      klass = value.key?("results") ? Objects::List : TYPES.fetch(value["object"], Objects::Unknown)
      klass.new(value)
    end

    def wrap_value(value)
      case value
      when Hash then value.key?("object") ? build(value) : value.transform_values { |item| wrap_value(item) }
      when Array then value.map { |item| wrap_value(item) }
      else value
      end
    end
  end
end
