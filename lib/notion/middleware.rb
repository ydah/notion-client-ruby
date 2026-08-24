# frozen_string_literal: true

require_relative "middleware/stack"
require_relative "middleware/json_codec"
require_relative "middleware/compatibility"
require_relative "middleware/api_version"
require_relative "middleware/authentication"
require_relative "middleware/rate_limiter"
require_relative "middleware/retry"
require_relative "middleware/logging"
require_relative "middleware/instrumentation"
