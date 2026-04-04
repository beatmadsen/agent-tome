require "fileutils"
require "tmpdir"
require "yaml"

module TomeDsl
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test")
    @db_path = File.join(@tmp_dir, "test.db")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    File.write(File.join(@config_dir, "config.yml"), YAML.dump("db_path" => @db_path))
    @tome_driver = build_driver
    super
  end

  def teardown
    super
    @tome_driver&.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def tome
    @tome_driver
  end

  def assert_success(result, message = nil)
    msg = message || "Expected success but got error: #{result.error_message}"
    assert result.success?, msg
  end

  def assert_global_id(value, message = nil)
    msg = message || "Expected a 7-character base58 global ID, got #{value.inspect}"
    assert_match BASE58_PATTERN, value, msg
  end

  def create_article!(**opts)
    opts[:description] ||= "Test article"
    opts[:body] ||= "Test body"
    result = tome.create(**opts)
    assert result.success?, "create_article! failed: #{result.error_message}"
    result
  end

  private

  def build_driver
    driver_class = ENV.fetch("TOME_DRIVER", "service") == "cli" ? CliDriver : ServiceDriver
    driver_class.new(db_path: @db_path, config_dir: @config_dir)
  end
end
