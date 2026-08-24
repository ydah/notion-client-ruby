# frozen_string_literal: true

module Notion
  module Middleware
    class Stack
      def self.build(adapter, config)
        app = JsonCodec.new(adapter)
        app = Compatibility.new(app, config)
        app = ApiVersion.new(app, config)
        app = Authentication.new(app, config)
        key = config.token || (config.token_store && [config.token_store.object_id, config.token_key])
        store = config.rate_limit_store || RateLimiter::DEFAULT_STORE
        app = RateLimiter.new(app, rate: config.rate, burst: config.burst, key: key, store: store)
        app = Retry.new(app, max_attempts: config.max_attempts, cap: config.retry_cap)
        app = Logging.new(app, logger: config.logger, level: config.log_level)
        Instrumentation.new(app)
      end
    end
  end
end
