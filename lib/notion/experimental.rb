# frozen_string_literal: true

module Notion
  class Experimental
    def initialize(client)
      @client = client
    end

    def agents = @client.agents
    def sessions = @client.sessions
  end
end
