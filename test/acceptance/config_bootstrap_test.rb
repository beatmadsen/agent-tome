require "test_helper"

# AT-1.1: First run creates config directory
class ConfigBootstrapTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-bootstrap-test")
    # Intentionally do NOT create the config_dir — test that the tool creates it
    @config_dir = File.join(@tmp_dir, "agent-tome-config")
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_first_run_creates_config_directory_and_config_file
    refute File.directory?(@config_dir), "Precondition: config dir should not exist yet"

    config = Agent::Tome::Config.new(config_dir: @config_dir)
    config.load!

    assert File.directory?(@config_dir),
           "Config directory should be created on first run"

    config_file = File.join(@config_dir, "config.yml")
    assert File.exist?(config_file),
           "config.yml should be created on first run"

    loaded = YAML.load_file(config_file)
    assert loaded.is_a?(Hash), "config.yml should contain a Hash"
    assert loaded.key?("db_path"),
           "config.yml should have a db_path key, got: #{loaded.inspect}"
    refute loaded["db_path"].to_s.strip.empty?,
           "db_path should not be empty"
  end
end
