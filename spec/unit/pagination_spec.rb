# frozen_string_literal: true

RSpec.describe Notion::Objects::List do
  it "enumerates all cursor pages lazily" do
    first = described_class.new(
      "object" => "list",
      "results" => [{ "object" => "page", "id" => "one" }],
      "has_more" => true,
      "next_cursor" => "next"
    )
    second = described_class.new(
      "object" => "list",
      "results" => [{ "object" => "page", "id" => "two" }],
      "has_more" => false,
      "next_cursor" => nil
    )
    first.with_fetcher { |cursor| cursor == "next" ? second : raise("unexpected cursor") }

    expect(first.each_result.map(&:id)).to eq(%w[one two])
  end

  it "is exposed through CursorPaginator" do
    list = described_class.new("results" => [{ "object" => "page", "id" => "one" }], "has_more" => false)
    paginator = Notion::Pagination::CursorPaginator.new(list)

    expect(paginator.map(&:id)).to eq(["one"])
    expect(paginator.each_page.to_a).to eq([list])
  end

  it "returns enumerators and stops without a fetcher" do
    list = described_class.new(
      "results" => [{ "object" => "page", "id" => "one" }], "has_more" => true, "next_cursor" => "next"
    )
    paginator = Notion::Pagination::CursorPaginator.new(list)

    expect(list.each).to be_a(Enumerator)
    expect(list.each_page.to_a).to eq([list])
    expect(list.each_result).to be_a(Enumerator)
    expect(paginator.each).to be_a(Enumerator)
  end

  it "publishes pagination counts" do
    events = []
    subscriber = Notion::Middleware::Instrumentation.subscribe { |name, payload| events << [name, payload] }
    list = described_class.new(
      "results" => [{ "object" => "page", "id" => "one" }], "has_more" => false
    )

    list.each_page.to_a

    expect(events).to include(["pagination.notion", { pages: 1, results: 1 }])
  ensure
    Notion::Middleware::Instrumentation.unsubscribe(subscriber) if subscriber
  end
end
