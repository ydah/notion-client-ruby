# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
require "notion"
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
puts format("require notion: %.2fms", elapsed * 1000)
abort "require exceeded 50ms" if elapsed >= 0.05
