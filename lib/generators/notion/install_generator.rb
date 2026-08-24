# frozen_string_literal: true

require "rails/generators"

module Notion
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "notion.rb", "config/initializers/notion.rb"
      end
    end
  end
end
