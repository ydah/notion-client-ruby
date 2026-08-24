# frozen_string_literal: true

RSpec.describe Notion::Multipart do
  it "encodes binary data and part numbers" do
    body, content_type = described_class.encode(
      "\x00data".b,
      filename: "sample.bin",
      content_type: "application/octet-stream",
      part_number: 2
    )

    expect(content_type).to start_with("multipart/form-data; boundary=")
    expect(body).to include('name="part_number"', "\x00data".b, 'filename="sample.bin"')
  end

  it "escapes quoted filenames and rejects header injection" do
    body, = described_class.encode("data", filename: 'say "hi".txt', content_type: "text/plain")

    expect(body).to include('filename="say \\"hi\\".txt"')
    expect { described_class.encode("data", filename: "x\r\nX: y", content_type: "text/plain") }
      .to raise_error(ArgumentError, /filename/)
    expect { described_class.encode("data", filename: "x", content_type: "text/plain\r\nX: y") }
      .to raise_error(ArgumentError, /content_type/)
  end
end
