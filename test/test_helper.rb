$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "agent/tome"

require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "yaml"

begin
  require "active_support"
  require "active_support/testing/parallelization"
  require "active_support/testing/parallelize_executor"
  require "concurrent"

  Minitest.parallel_executor = ActiveSupport::Testing::ParallelizeExecutor.new(
    size: Concurrent.processor_count,
    with: :processes,
    threshold: 0
  )
rescue LoadError, NameError
  # Fall back to default executor if parallel support is unavailable
end

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }
