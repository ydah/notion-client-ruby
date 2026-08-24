# frozen_string_literal: true

RSpec.describe Notion::Compat do
  let(:request) do
    Notion::Transport::Request.new(
      verb: :patch,
      path: "/v1/data_sources/id/query",
      query: {},
      headers: {},
      body: {
        in_trash: true,
        position: { "type" => "after_block", "after_block" => { "id" => "previous" } }
      },
      idempotent: false
    )
  end

  it "downgrades current request fields for the legacy API" do
    converted = described_class.request("2022-06-28", request)

    expect(converted.path).to eq("/v1/databases/id/query")
    expect(converted.body).to eq("archived" => true, "after" => "previous")
  end

  it "normalizes legacy response fields" do
    response = Notion::Transport::Response.new(
      status: 200,
      headers: {},
      body: { "archived" => true, "type" => "transcription", "transcription" => {} },
      request_id: nil,
      elapsed: 0
    )

    normalized = described_class.response("2025-09-03", response)

    expect(normalized.body).to include(
      "in_trash" => true, "type" => "meeting_notes", "meeting_notes" => {}
    )
  end

  it "rejects endpoints unavailable in an older version" do
    %w[/v1/views /v1/sessions /v1/blocks/meeting_notes/query].each do |path|
      expect { described_class.request("2025-09-03", request.with(path: path)) }
        .to raise_error(Notion::UnsupportedInVersionError)
    end
  end

  it "passes current and supported requests through" do
    expect(described_class.request("2026-03-11", request)).to equal(request)
    expect(described_class.request("2025-09-03", request.with(path: "/v1/pages/id")).path).to eq("/v1/pages/id")
  end

  it "recursively converts arrays and scalar response values" do
    body = {
      "children" => [{ "archived" => false }, [{ "archived" => true }], "plain"],
      "type" => "transcription",
      "transcription" => { "value" => 1 }
    }
    response = Notion::Transport::Response.new(
      status: 200, headers: {}, body: body, request_id: nil, elapsed: 0
    )

    expect(described_class.response("2022-06-28", response).body.dig("children", 0, "in_trash")).to be(false)
    expect(described_class.response("2022-06-28", response).body.dig("children", 1, 0, "in_trash")).to be(true)
    expect(described_class.response("2026-03-11", response)).to equal(response)
    expect(described_class.response("2022-06-28", response.with(body: "plain")).body).to eq("plain")
  end

  it "renames meeting notes only for the matching legacy version" do
    value = { type: "meeting_notes", meeting_notes: { "text" => "note" }, other: [1] }

    expect(described_class.downgrade(value, "2025-09-03")).to include("transcription")
    expect(described_class.downgrade(value, "2025-09-03")).to include("type" => "transcription")
    expect { described_class.downgrade(value, "2022-06-28") }
      .to raise_error(Notion::UnsupportedInVersionError)
    expect(described_class.downgrade(nil, "2022-06-28")).to be_nil
  end

  it "maps all legacy data source paths and parent IDs" do
    legacy = request.with(
      path: "/v1/data_sources/id",
      body: { parent: { data_source_id: "source" } }
    )
    converted = described_class.request("2022-06-28", legacy)

    expect(converted.path).to eq("/v1/databases/id")
    expect(converted.body.dig("parent", "database_id")).to eq("source")
    response = Notion::Transport::Response.new(
      status: 200, headers: {}, body: { "parent" => { "database_id" => "db" } }, request_id: nil, elapsed: 0
    )
    expect(described_class.response("2022-06-28", response).body.dig("parent", "data_source_id")).to eq("db")
  end

  it "rejects legacy data source templates" do
    unsupported = request.with(path: "/v1/data_sources/id/templates")

    expect { described_class.request("2022-06-28", unsupported) }
      .to raise_error(Notion::UnsupportedInVersionError)
  end
end
