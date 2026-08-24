# frozen_string_literal: true

# This file is generated. DO NOT EDIT.

require_relative "generated/endpoints/agents"
require_relative "generated/endpoints/async_tasks"
require_relative "generated/endpoints/blocks"
require_relative "generated/endpoints/comments"
require_relative "generated/endpoints/custom_emojis"
require_relative "generated/endpoints/data_sources"
require_relative "generated/endpoints/databases"
require_relative "generated/endpoints/file_uploads"
require_relative "generated/endpoints/meeting_notes"
require_relative "generated/endpoints/oauth"
require_relative "generated/endpoints/pages"
require_relative "generated/endpoints/search"
require_relative "generated/endpoints/sessions"
require_relative "generated/endpoints/users"
require_relative "generated/endpoints/views"

module Notion
  module Generated
    RESOURCES = {
      agents: Endpoints::Agents,
      async_tasks: Endpoints::AsyncTasks,
      blocks: Endpoints::Blocks,
      comments: Endpoints::Comments,
      custom_emojis: Endpoints::CustomEmojis,
      data_sources: Endpoints::DataSources,
      databases: Endpoints::Databases,
      file_uploads: Endpoints::FileUploads,
      meeting_notes: Endpoints::MeetingNotes,
      oauth: Endpoints::Oauth,
      pages: Endpoints::Pages,
      search: Endpoints::Search,
      sessions: Endpoints::Sessions,
      users: Endpoints::Users,
      views: Endpoints::Views
    }.freeze
  end
end
