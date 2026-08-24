# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

module Notion
  module Generated
    module Endpoints
      class FileUploads < Notion::Endpoints::Base
      operation :create, :post, "/v1/file_uploads", path: [], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: [], variants: [], enums: {"mode" => ["single_part", "multi_part", "external_url"]}, max_lengths: {} }
      operation :list, :get, "/v1/file_uploads", path: [], query: ["status", "start_cursor", "page_size"], query_rules: { required: [], enums: {"status" => ["pending", "uploaded", "expired", "failed"]}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :send, :post, "/v1/file_uploads/{file_upload_id}/send", path: ["file_upload_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: true, required: ["data", "filename", "content_type"], variants: [["data", "filename", "content_type"]], enums: {}, max_lengths: {} }
      operation :complete, :post, "/v1/file_uploads/{file_upload_id}/complete", path: ["file_upload_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }
      operation :retrieve, :get, "/v1/file_uploads/{file_upload_id}", path: ["file_upload_id"], query: [], query_rules: { required: [], enums: {}, max_lengths: {} }, body_rules: { send_empty: false, required: [], variants: [], enums: {}, max_lengths: {} }

    # Create a file upload
    # @see https://developers.notion.com/reference/create-file
    def create(**params, &block)

      invoke_operation(:create, params, &block)
    end
    # List file uploads
    # @see https://developers.notion.com/reference/list-file-uploads
    def list(**params, &block)

      invoke_operation(:list, params, &block)
    end
    # Upload a file
    # @see https://developers.notion.com/reference/upload-file
    def send(file_upload_id:, data:, filename:, content_type:, **params, &block)
        params[:file_upload_id] = file_upload_id
        params[:data] = data
        params[:filename] = filename
        params[:content_type] = content_type
      invoke_operation(:send, params, &block)
    end
    # Complete a multi-part file upload
    # @see https://developers.notion.com/reference/complete-file-upload
    def complete(file_upload_id:, **params, &block)
        params[:file_upload_id] = file_upload_id
      invoke_operation(:complete, params, &block)
    end
    # Retrieve a file upload
    # @see https://developers.notion.com/reference/retrieve-file-upload
    def retrieve(file_upload_id:, **params, &block)
        params[:file_upload_id] = file_upload_id
      invoke_operation(:retrieve, params, &block)
    end
      end
    end
  end
end
