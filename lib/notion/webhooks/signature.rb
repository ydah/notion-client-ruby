# frozen_string_literal: true

require "openssl"

module Notion
  module Webhooks
    module Signature
      module_function

      def valid?(secret:, payload:, signature:)
        expected = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
        secure_compare?(expected, signature.to_s.delete_prefix("sha256="))
      end

      def secure_compare?(left, right)
        return false unless left.bytesize == right.bytesize

        left.bytes.zip(right.bytes).reduce(0) { |difference, (a, b)| difference | (a ^ b) }.zero?
      end
    end
  end
end
