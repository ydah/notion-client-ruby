# frozen_string_literal: true

module Notion
  module Generated
    module Endpoints
      class FileUploads
        def send(file_upload_id:, data:, filename:, content_type:, part_number: nil)
          send_part(
            file_upload_id: file_upload_id,
            data: data,
            filename: filename,
            content_type: content_type,
            part_number: part_number
          )
        end

        def send_part(file_upload_id:, data:, filename:, content_type:, part_number: nil)
          body, header = Multipart.encode(
            data,
            filename: filename,
            content_type: content_type,
            part_number: part_number
          )
          @client.request(
            :post,
            "/v1/file_uploads/#{URI.encode_uri_component(file_upload_id)}/send",
            headers: { "content-type" => header },
            body: body,
            idempotent: !part_number.nil?
          )
        end
      end
    end
  end
end
