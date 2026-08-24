# frozen_string_literal: true

module Notion
  module Pagination
    class CursorPaginator
      include Enumerable

      def initialize(list)
        @list = list
      end

      def each(&block)
        return enum_for(__method__) unless block

        @list.each_result(&block)
      end

      alias each_result each

      def each_page(&)
        @list.each_page(&)
      end
    end
  end
end
