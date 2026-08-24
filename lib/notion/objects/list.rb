# frozen_string_literal: true

require_relative "../middleware/instrumentation"

module Notion
  module Objects
    class List < Base
      include Enumerable

      def results
        @results ||= Array(raw["results"]).map { |result| ObjectFactory.build(result) }
      end

      def next_cursor = raw["next_cursor"]
      def has_more? = !!raw["has_more"]

      def each(&block)
        return enum_for(__method__) unless block

        results.each(&block)
      end

      def each_page
        return enum_for(__method__) unless block_given?

        page = self
        pages = 0
        results = 0
        loop do
          pages += 1
          results += page.results.length
          yield page
          break unless page.has_more? && page.fetcher

          page = page.fetcher.call(page.next_cursor)
        end
        Middleware::Instrumentation.publish("pagination.notion", pages: pages, results: results)
      end

      def each_result(&block)
        return enum_for(__method__) unless block

        each_page { |page| page.results.each(&block) }
      end

      def with_fetcher(&fetcher)
        @fetcher = fetcher
        self
      end

      protected

      attr_reader :fetcher
    end
  end
end
