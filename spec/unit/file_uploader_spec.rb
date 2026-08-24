# frozen_string_literal: true

require "stringio"
require "tempfile"

RSpec.describe Notion::FileUploader do
  let(:uploads) do
    Class.new do
      attr_reader :created, :parts

      def initialize
        @parts = []
      end

      def create(**params)
        @created = params
        Notion::Objects::File.new("object" => "file_upload", "id" => "upload")
      end

      def send_part(**params)
        @parts << params
      end

      def complete(file_upload_id:)
        Notion::Objects::File.new("object" => "file_upload", "id" => file_upload_id, "status" => "uploaded")
      end

      def retrieve(file_upload_id:)
        Notion::Objects::File.new("object" => "file_upload", "id" => file_upload_id, "status" => "uploaded")
      end
    end.new
  end
  let(:client) { Struct.new(:file_uploads).new(uploads) }
  let(:uploader) { described_class.new(client) }

  it "uploads a small IO as one part without null API fields" do
    progress = []

    result = uploader.upload(
      io: StringIO.new("data"),
      filename: "data.txt",
      content_type: "text/plain",
      on_progress: ->(*values) { progress << values }
    )

    expect(result.id).to eq("upload")
    expect(uploads.created).to eq(mode: "single_part", filename: "data.txt", content_type: "text/plain")
    expect(uploads.parts.first).to include(data: "data", part_number: nil)
    expect(progress).to eq([[4, 4]])
  end

  it "spools and splits an IO with an unknown size" do
    stub_const("Notion::FileUploader::PART_SIZE", 4)
    io = Object.new
    chunks = ["data", "!", nil]
    io.define_singleton_method(:read) { |_size| chunks.shift }
    progress = []

    result = uploader.upload(io: io, on_progress: ->(*values) { progress << values })

    expect(result.id).to eq("upload")
    expect(uploads.created).to include(mode: "multi_part", number_of_parts: 2)
    expect(uploads.parts.map { |part| part[:data] }.sort).to eq(["!", "data"])
    expect(progress.last).to eq([5, 5])
  end

  it "numbers and completes a multipart upload" do
    io = Object.new
    io.define_singleton_method(:size) { Notion::FileUploader::PART_SIZE + 1 }
    chunks = ["first", "second", nil]
    io.define_singleton_method(:read) { |_size| chunks.shift }

    result = uploader.upload(io: io, filename: "large.bin")

    expect(uploads.created[:number_of_parts]).to eq(2)
    expect(uploads.parts.map { |part| part[:part_number] }.sort).to eq([1, 2])
    expect(result.status).to eq("uploaded")
  end

  it "validates multipart concurrency" do
    expect { uploader.upload(io: StringIO.new("data"), concurrency: 0) }.to raise_error(ArgumentError, /positive/)
  end

  it "validates external import URLs" do
    expect { uploader.import(url: "file:///etc/passwd") }.to raise_error(ArgumentError)

    uploader.import(url: "https://example.test/file")
    expect(uploads.created).to eq(mode: "external_url", external_url: "https://example.test/file")
  end

  it "supports asynchronous import control and failures" do
    pending = Notion::Objects::File.new("object" => "file_upload", "id" => "upload", "status" => "pending")
    failed = pending.raw.merge("status" => "failed")
    allow(uploads).to receive_messages(
      create: pending,
      retrieve: Notion::Objects::File.new(failed)
    )
    expect(uploader.import(url: "https://example.test/file", wait: false)).to equal(pending)

    expect { uploader.import(url: "https://example.test/file", interval: 0) }
      .to raise_error(Notion::Error, /failed/)
  end

  it "requires input and accepts a path" do
    expect { uploader.upload }.to raise_error(ArgumentError, /path or io/)

    Tempfile.create(["upload", ".txt"]) do |file|
      file.write("data")
      file.flush
      expect(uploader.upload(path: file.path).id).to eq("upload")
      expect(uploads.created[:filename]).to end_with(".txt")
    end
  end
end
