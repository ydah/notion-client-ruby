# frozen_string_literal: true

module Notion
  if defined?(Rails::Railtie)
    class Railtie < Rails::Railtie
      initializer "notion-client-ruby.configure" do
        Notion.configure { |config| config.logger ||= Rails.logger }
      end
    end
  end
end
