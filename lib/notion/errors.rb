# frozen_string_literal: true

module Notion
  class Error < StandardError; end

  class TransportError < Error
    attr_reader :cause

    def initialize(message, cause: nil)
      @cause = cause
      super(message)
    end
  end

  class TimeoutError < TransportError; end

  class APIError < Error
    attr_reader :status, :code, :request_id, :additional_data, :response, :retry_after

    def initialize(response)
      unless response.respond_to?(:body)
        super(response.to_s)
        return
      end

      body = response.body.is_a?(Hash) ? response.body : {}
      @status = response.status
      @code = body["code"]
      @request_id = response.request_id || body["request_id"]
      @additional_data = body["additional_data"]
      @retry_after = response.headers["retry-after"]&.to_f
      @response = response
      super(body["message"] || "Notion API request failed with status #{@status}")
    end

    def retryable?
      status == 429 || status == 529 || status.between?(500, 599)
    end

    def self.from_response(response)
      code = response.body.is_a?(Hash) && response.body["code"]
      (ERROR_CODES[code] || STATUS_ERRORS[response.status] || self).new(response)
    end
  end

  class BadRequestError < APIError; end
  class InvalidJSONError < BadRequestError; end
  class InvalidRequestURLError < BadRequestError; end
  class InvalidRequestError < BadRequestError; end
  class InvalidGrantError < BadRequestError; end
  class ValidationError < BadRequestError; end
  class MissingVersionError < BadRequestError; end
  class InvalidBetaError < BadRequestError; end
  class UnauthorizedError < APIError; end
  class RestrictedResourceError < APIError; end
  class ObjectNotFoundError < APIError; end
  class ConflictError < APIError; end
  class RateLimitedError < APIError; end
  class ServerError < APIError; end
  class InternalServerError < ServerError; end
  class BadGatewayError < ServerError; end
  class ServiceUnavailableError < ServerError; end
  class DatabaseConnectionUnavailableError < ServiceUnavailableError; end
  class GatewayTimeoutError < ServerError; end
  class ServiceOverloadError < ServerError; end
  class UnsupportedInVersionError < Error; end

  class PartialAppendError < Error
    attr_reader :successful_ids, :cause

    def initialize(message, successful_ids:, cause: nil)
      @successful_ids = successful_ids
      @cause = cause
      super(message)
    end
  end

  APIError::ERROR_CODES = {
    "invalid_json" => InvalidJSONError,
    "invalid_request_url" => InvalidRequestURLError,
    "invalid_request" => InvalidRequestError,
    "invalid_grant" => InvalidGrantError,
    "validation_error" => ValidationError,
    "missing_version" => MissingVersionError,
    "invalid_beta" => InvalidBetaError,
    "unauthorized" => UnauthorizedError,
    "restricted_resource" => RestrictedResourceError,
    "object_not_found" => ObjectNotFoundError,
    "conflict_error" => ConflictError,
    "rate_limited" => RateLimitedError,
    "internal_server_error" => InternalServerError,
    "bad_gateway" => BadGatewayError,
    "service_unavailable" => ServiceUnavailableError,
    "database_connection_unavailable" => DatabaseConnectionUnavailableError,
    "gateway_timeout" => GatewayTimeoutError,
    "service_overload" => ServiceOverloadError
  }.freeze
  APIError::STATUS_ERRORS = {
    400 => BadRequestError,
    401 => UnauthorizedError,
    403 => RestrictedResourceError,
    404 => ObjectNotFoundError,
    409 => ConflictError,
    429 => RateLimitedError,
    500 => InternalServerError,
    502 => BadGatewayError,
    503 => ServiceUnavailableError,
    504 => GatewayTimeoutError,
    529 => ServiceOverloadError
  }.freeze
end
