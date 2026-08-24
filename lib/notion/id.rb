# frozen_string_literal: true

module Notion
  module ID
    module_function

    def normalize(value)
      hex = value.to_s.delete("-").downcase
      raise ArgumentError, "invalid Notion ID" unless hex.match?(/\A[0-9a-f]{32}\z/)

      [8, 4, 4, 4, 12].map { |size| hex.slice!(0, size) }.join("-")
    end
  end
end
