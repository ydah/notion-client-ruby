# frozen_string_literal: true

module Notion
  module Generated
    module Endpoints
      class AsyncTasks
        TERMINAL = %w[success completed failed canceled cancelled].freeze

        def wait(task_id:, timeout: 300, interval: 1, sleeper: Kernel.method(:sleep))
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
          attempt = 0
          loop do
            task = retrieve(task_id: task_id)
            status = task.status.to_s
            raise Error, "async task #{status}" if status.match?(/fail|cancel/)
            return task if TERMINAL.include?(status)
            raise TimeoutError, "async task timed out" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

            sleeper.call(interval == :exponential ? [2**attempt, 30].min : interval)
            attempt += 1
          end
        end
      end
    end
  end
end
