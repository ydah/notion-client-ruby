# frozen_string_literal: true

RSpec.describe Notion::Batch do
  it "runs jobs concurrently and preserves result order" do
    active = 0
    maximum = 0
    mutex = Mutex.new
    client = Notion::Client.new(token: "token", adapter: Notion::Testing::Adapter.new)

    results = client.batch(concurrency: 2) do |batch|
      3.times do |value|
        batch.call do
          mutex.synchronize { maximum = [maximum, active += 1].max }
          sleep(0.01)
          mutex.synchronize { active -= 1 }
          value
        end
      end
    end

    expect(results).to eq([0, 1, 2])
    expect(maximum).to eq(2)
  end

  it "validates concurrency and blocks" do
    expect { described_class.new(0) }.to raise_error(ArgumentError, /positive/)
    expect { described_class.new("2") }.to raise_error(ArgumentError, /positive integer/)
    expect { described_class.new(1).call }.to raise_error(ArgumentError, /job block/)
    expect { Notion::Client.new(token: "token").batch }.to raise_error(ArgumentError, /batch block/)
  end

  it "finishes remaining jobs and propagates failures" do
    completed = false
    batch = described_class.new(1).call { raise "failed" }.call { completed = true }
    expect { batch.run }.to raise_error("failed")
    expect(completed).to be(true)
  end
end
