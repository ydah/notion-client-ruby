# frozen_string_literal: true

module Notion
  module Middleware
    class Compatibility
      def initialize(app, config)
        @app = app
        @version = config.notion_version
      end

      def call(request)
        response = @app.call(Compat.request(@version, request))
        Compat.response(@version, response)
      end
    end
  end
end
