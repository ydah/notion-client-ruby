# frozen_string_literal: true

module Notion
  module Middleware
    class ApiVersion
      def initialize(app, config)
        @app = app
        @config = config
      end

      def call(request)
        headers = request.headers.merge("notion-version" => @config.notion_version)
        headers["notion-beta"] = @config.betas.join(",") unless @config.betas.empty?
        @app.call(request.with(headers: headers))
      end
    end
  end
end
