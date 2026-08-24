# frozen_string_literal: true

RSpec.describe "view query cleanup" do
  it "deletes the temporary query when the block raises" do
    endpoints = Class.new(Notion::Generated::Endpoints::Views) do
      attr_reader :deleted

      def create_query(view_id:, **)
        Notion::Objects::View.new("object" => "view", "id" => "query", "view_id" => view_id)
      end

      def query_results(**)
        Notion::Objects::List.new("results" => [], "has_more" => false)
      end

      def delete_query(view_id:, query_id:)
        @deleted = [view_id, query_id]
      end
    end.new(nil)

    expect { endpoints.with_query(view_id: "view") { raise "stop" } }.to raise_error("stop")
    expect(endpoints.deleted).to eq(%w[view query])
  end
end
