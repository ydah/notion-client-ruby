# frozen_string_literal: true

module Notion
  class Batch
    def initialize(concurrency)
      unless concurrency.is_a?(Integer) && concurrency.positive?
        raise ArgumentError, "concurrency must be a positive integer"
      end

      @concurrency = concurrency
      @jobs = []
    end

    def call(&job)
      raise ArgumentError, "a job block is required" unless job

      @jobs << job
      self
    end

    def run
      queue = Queue.new
      @jobs.each_with_index { |job, index| queue << [index, job] }
      results = Array.new(@jobs.length)
      errors = Array.new(@jobs.length)
      Array.new([@concurrency, @jobs.length].min) do
        Thread.new do
          while (entry = queue.pop(true))
            index, job = entry
            begin
              results[index] = job.call
            rescue StandardError => e
              errors[index] = e
            end
          end
        rescue ThreadError
          nil
        end
      end.each(&:join)
      raise errors.compact.first if errors.any?

      results
    end
  end
end
