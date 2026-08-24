# frozen_string_literal: true

require_relative "notion/version"
require_relative "notion/config"
require_relative "notion/errors"
require_relative "notion/railtie"

module Notion
  LATEST_API_VERSION = "2026-03-11"

  autoload :Blocks, "notion/blocks"
  autoload :Batch, "notion/batch"
  autoload :Client, "notion/client"
  autoload :Compat, "notion/compat"
  autoload :FileUploader, "notion/file_uploader"
  autoload :Generated, "notion/client"
  autoload :ID, "notion/id"
  autoload :Markdown, "notion/markdown/local_converter"
  autoload :Middleware, "notion/middleware"
  autoload :Multipart, "notion/multipart"
  autoload :ObjectFactory, "notion/object_factory"
  autoload :Objects, "notion/objects"
  autoload :OAuth, "notion/oauth"
  autoload :Pagination, "notion/pagination/cursor_paginator"
  autoload :Query, "notion/query"
  autoload :Resolver, "notion/resolver"
  autoload :Testing, "notion/testing"
  autoload :Transport, "notion/transport"
  autoload :Webhooks, "notion/webhooks"

  class << self
    def configuration
      @configuration ||= Config.new
    end

    def configure
      yield(configuration)
      configuration.validate!
    end

    def new(**options)
      Client.new(**options)
    end

    def blocks(&)
      Blocks::Builder.build(&)
    end

    def reset_configuration!
      @configuration = Config.new
    end
  end
end
