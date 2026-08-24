# frozen_string_literal: true

RSpec.describe Notion::Generated::Endpoints::AsyncTasks do
  it "polls until a task completes" do
    endpoint = described_class.new(Object.new)
    statuses = %w[in_progress success]
    endpoint.define_singleton_method(:retrieve) do |task_id:|
      raise "unexpected id" unless task_id == "task"

      Notion::Objects::AsyncTask.new("status" => statuses.shift)
    end
    waits = []

    result = endpoint.wait(task_id: "task", interval: :exponential, sleeper: ->(delay) { waits << delay })

    expect(result.status).to eq("success")
    expect(waits).to eq([1])
  end

  it "raises on failure and timeout" do
    endpoint = described_class.new(Object.new)
    endpoint.define_singleton_method(:retrieve) do |task_id:|
      Notion::Objects::AsyncTask.new("status" => task_id)
    end

    expect { endpoint.wait(task_id: "failed") }.to raise_error(Notion::Error, /failed/)
    expect { endpoint.wait(task_id: "pending", timeout: -1, interval: 0) }
      .to raise_error(Notion::TimeoutError, /timed out/)
  end
end
