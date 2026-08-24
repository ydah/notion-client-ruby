# frozen_string_literal: true

require "securerandom"

module Notion
  module Multipart
    module_function

    def encode(data, filename:, content_type:, part_number: nil)
      filename = quoted_header_value(filename, "filename")
      content_type = header_value(content_type, "content_type")
      boundary = "notion-#{SecureRandom.hex(12)}"
      body = +"".b
      append_field(body, boundary, "part_number", part_number.to_s) if part_number
      body << "--#{boundary}\r\n"
      body << %(Content-Disposition: form-data; name="file"; filename="#{filename}"\r\n)
      body << "Content-Type: #{content_type}\r\n\r\n"
      body << data.b << "\r\n--#{boundary}--\r\n"
      [body, "multipart/form-data; boundary=#{boundary}"]
    end

    def header_value(value, name)
      value = value.to_s
      raise ArgumentError, "#{name} cannot contain newlines" if value.match?(/[\r\n]/)

      value
    end

    def quoted_header_value(value, name)
      header_value(value, name).gsub(/[\\"]/) { |character| "\\#{character}" }
    end

    def append_field(body, boundary, name, value)
      body << "--#{boundary}\r\n"
      body << %(Content-Disposition: form-data; name="#{name}"\r\n\r\n)
      body << "#{value}\r\n"
    end
  end
end
