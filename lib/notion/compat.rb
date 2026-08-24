# frozen_string_literal: true

module Notion
  module Compat
    module_function

    def request(version, request)
      reject_unsupported!(version, request.path)
      return request if version == "2026-03-11"

      path = request.path
      path = path.sub(%r{\A/v1/data_sources(?=/|\z)}, "/v1/databases") if version == "2022-06-28"
      request.with(path: path, body: downgrade(request.body, version))
    end

    def response(version, response)
      return response if version == "2026-03-11" || !response.body.is_a?(Hash)

      response.with(body: normalize(response.body, version))
    end

    def downgrade(value, version)
      case value
      when Array then value.map { |item| downgrade(item, version) }
      when Hash then value.to_h { |key, item| downgrade_pair(key, item, version) }
      else value
      end
    end

    def downgrade_pair(key, item, version)
      reject_meeting_notes!(key, item, version)
      if key.to_s == "position" && item.is_a?(Hash) && item["type"] == "after_block"
        return ["after", item.dig("after_block", "id")]
      end

      new_key = downgrade_key(key, version)
      new_item = downgrade_value(key, item, version)
      [new_key, new_item]
    end

    def reject_meeting_notes!(key, item, version)
      meeting_notes = key.to_s == "meeting_notes" || (key.to_s == "type" && item == "meeting_notes")
      return unless version == "2022-06-28" && meeting_notes

      raise UnsupportedInVersionError, "meeting_notes is unavailable in Notion API #{version}"
    end

    def downgrade_value(key, item, version)
      return "transcription" if key.to_s == "type" && item == "meeting_notes"

      downgrade(item, version)
    end

    def downgrade_key(key, version)
      key = key.to_s
      return "archived" if key == "in_trash"
      return "transcription" if version == "2025-09-03" && key == "meeting_notes"
      return "database_id" if version == "2022-06-28" && key == "data_source_id"

      key
    end

    def normalize(value, version)
      value.each_with_object({}) do |(key, item), result|
        new_key = { "archived" => "in_trash", "transcription" => "meeting_notes" }.fetch(key, key)
        new_key = "data_source_id" if version == "2022-06-28" && new_key == "database_id"
        result[new_key] = if key == "type" && item == "transcription"
                            "meeting_notes"
                          else
                            normalize_value(item, version)
                          end
      end
    end

    def normalize_value(item, version)
      case item
      when Hash then normalize(item, version)
      when Array then item.map { |entry| normalize_value(entry, version) }
      else item
      end
    end

    def reject_unsupported!(version, path)
      return if version == "2026-03-11"

      unsupported = path.match?(%r{\A/v1/(views|agents|sessions)(?=/|\z)}) || path.end_with?("/markdown")
      unsupported ||= path.match?(%r{\A/v1/blocks/meeting_notes(?=/|\z)})
      unsupported ||= version == "2022-06-28" && path.match?(%r{\A/v1/data_sources/[^/]+/templates})
      return unless unsupported

      raise UnsupportedInVersionError, "#{path} is unavailable in Notion API #{version}"
    end
  end
end
