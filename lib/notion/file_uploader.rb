# frozen_string_literal: true

require "uri"
require "tempfile"

module Notion
  class FileUploader
    PART_SIZE = 20 * 1024 * 1024

    def initialize(client)
      @client = client
    end

    def upload(path: nil, io: nil, filename: nil, content_type: "application/octet-stream", on_progress: nil,
               concurrency: 3)
      raise ArgumentError, "concurrency must be positive" unless concurrency.to_i.positive?

      if path
        return File.open(path, "rb") do |file|
          upload_io(file, filename || File.basename(path), content_type, on_progress, concurrency)
        end
      end

      raise ArgumentError, "path or io is required" unless io

      upload_io(io, filename || "upload.bin", content_type, on_progress, concurrency)
    end

    def import(url:, filename: nil, content_type: nil, wait: true, timeout: 300, interval: 1,
               sleeper: Kernel.method(:sleep))
      uri = URI(url)
      raise ArgumentError, "URL must use http or https" unless %w[http https].include?(uri.scheme)

      upload = @client.file_uploads.create(**{
        mode: "external_url",
        external_url: url,
        filename: filename,
        content_type: content_type
      }.compact)
      wait ? wait_for_upload(upload, timeout, interval, sleeper) : upload
    end

    private

    def wait_for_upload(upload, timeout, interval, sleeper)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      loop do
        status = upload.respond_to?(:status) ? upload.status.to_s : ""
        return upload if status == "uploaded"
        raise Error, "file import #{status}" if status.match?(/fail|expire/)
        raise TimeoutError, "file import timed out" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

        sleeper.call(interval)
        upload = @client.file_uploads.retrieve(file_upload_id: upload.id)
      end
    end

    def upload_io(io, filename, content_type, on_progress, concurrency)
      size = io.respond_to?(:size) ? io.size : nil
      return upload_unsized(io, filename, content_type, on_progress, concurrency) unless size

      mode = size > PART_SIZE ? "multi_part" : "single_part"
      parts = (size.to_f / PART_SIZE).ceil
      create_params = {
        mode: mode,
        filename: filename,
        content_type: content_type
      }
      create_params[:number_of_parts] = parts if mode == "multi_part"
      upload = @client.file_uploads.create(**create_params)
      options = { filename: filename, content_type: content_type, size: size, on_progress: on_progress,
                  concurrency: concurrency }
      send_parts(upload.id, io, mode, options)
      mode == "multi_part" ? @client.file_uploads.complete(file_upload_id: upload.id) : upload
    end

    def upload_unsized(io, filename, content_type, on_progress, concurrency)
      Tempfile.create("notion-upload") do |file|
        loop do
          chunk = io.read(PART_SIZE)
          break unless chunk

          file.write(chunk)
        end
        file.flush
        file.rewind
        upload_io(file, filename, content_type, on_progress, concurrency)
      end
    end

    def send_parts(id, io, mode, options)
      if mode == "multi_part"
        return send_parts_in_parallel(
          id, io, options[:filename], options[:content_type], options[:size], options[:on_progress],
          options[:concurrency]
        )
      end

      send_part(id, io.read(PART_SIZE), options[:filename], options[:content_type], nil)
      options[:on_progress]&.call(options[:size], options[:size])
    end

    def send_parts_in_parallel(id, io, filename, content_type, size, on_progress, concurrency)
      read_mutex = Mutex.new
      progress_mutex = Mutex.new
      sent = 0
      part = 0
      errors = Queue.new
      workers = Array.new(concurrency) do
        Thread.new do
          loop do
            job = read_mutex.synchronize do
              data = io.read(PART_SIZE)
              data && [part += 1, data]
            end
            break unless job

            send_part(id, job.last, filename, content_type, job.first)
            progress_mutex.synchronize do
              sent += job.last.bytesize
              on_progress&.call(sent, size)
            end
          end
        rescue StandardError => e
          errors << e
        end
      end
      workers.each(&:join)
      raise errors.pop unless errors.empty?
    end

    def send_part(id, data, filename, content_type, part_number)
      @client.file_uploads.send_part(
        file_upload_id: id,
        data: data,
        filename: filename,
        content_type: content_type,
        part_number: part_number
      )
    end
  end
end
