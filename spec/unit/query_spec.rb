# frozen_string_literal: true

RSpec.describe Notion::Query::Builder do
  it "builds filters and sorts" do
    query = described_class.new
    query.where(:Name).contains("plan")
    query.order(:Created, direction: :descending)

    expect(query.to_h).to eq(
      filter: { property: "Name", rich_text: { contains: "plan" } },
      sorts: [{ property: "Created", direction: :descending }]
    )
  end

  it "uses the property type from the schema and validates strict names" do
    query = described_class.new(schema: { "Status" => { "type" => "status" } }, strict: true)

    query.where(:Status).equals("Done")

    expect(query.to_h[:filter]).to eq(property: "Status", status: { equals: "Done" })
    expect { query.where(:Missing).equals("x") }.to raise_error(Notion::Query::UnknownPropertyError)
  end

  it "combines typed, raw, and timestamp expressions" do
    left = described_class.new.where(:Done, type: :checkbox).equals(true)
    query = described_class.new
    query.all_of(left, { property: "Count", number: { greater_than: 1 } })
    query.any_of({ property: "A" }, { property: "B" })
    query.raw(timestamp: "created_time", created_time: { past_week: {} })
    query.order(timestamp: :last_edited_time, direction: :descending)

    expect(query.to_h[:filter][:and].length).to eq(3)
    expect(query.to_h[:sorts]).to eq([{ timestamp: :last_edited_time, direction: :descending }])
    expect(described_class.new.to_h).to eq({})
  end

  it "supports the documented chaining and valueless operators" do
    query = described_class.new(schema: { Priority: { type: "number" } })
    query.where(:Status).equals("Open")
         .and(query.where(:Priority).greater_than(3))
    query.order_by_timestamp(:last_edited_time, :descending)

    expect(query.to_h[:filter]).to have_key(:and)
    expect(query.to_h[:sorts]).to eq([{ timestamp: :last_edited_time, direction: :descending }])

    period = described_class.new.where(:Due, type: :date).past_week
    expect(period.to_h.dig(:filter, :date, :past_week)).to eq({})
  end

  it "groups the last two filters with or" do
    query = described_class.new
    query.where(:A).equals(1)
    query.or(query.where(:B).equals(2))

    expect(query.to_h[:filter]).to eq(
      or: [
        { property: "A", rich_text: { equals: 1 } },
        { property: "B", rich_text: { equals: 2 } }
      ]
    )
  end

  it "combines independent builders and validates an empty or" do
    left = described_class.new.raw(property: "A")
    right = described_class.new.raw(property: "B")

    expect(left.or(right).to_h[:filter]).to eq(or: [{ property: "A" }, { property: "B" }])
    expect(described_class.new.and(right).to_h[:filter]).to eq(property: "B")
    expect { described_class.new.or(right) }.to raise_error(ArgumentError, /left filter/)
  end

  it "rejects malformed filters before sending them" do
    query = described_class.new

    expect { query.where(nil).equals("x") }.to raise_error(ArgumentError, /property/)
    expect { query.all_of }.to raise_error(ArgumentError, /filter/)
    expect { query.any_of }.to raise_error(ArgumentError, /filter/)
  end

  it "rejects malformed sorts before sending them" do
    query = described_class.new

    expect { query.order }.to raise_error(ArgumentError, /either/)
    expect { query.order(:Name, timestamp: :created_time) }.to raise_error(ArgumentError, /either/)
    expect { query.order(:Name, direction: :sideways) }.to raise_error(ArgumentError, /direction/)
  end
end
