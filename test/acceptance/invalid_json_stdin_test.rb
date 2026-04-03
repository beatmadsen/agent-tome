require "test_helper"
require "open3"

# AT-10.5: Invalid JSON on stdin is rejected
# When agent-tome create receives `{invalid json` on stdin
# Then exit code is non-zero, JSON error about malformed input.
class InvalidJsonStdinTest < Minitest::Test
  BIN_PATH = File.expand_path("../../exe/agent-tome", __dir__)
  LIB_PATH = File.expand_path("../../lib", __dir__)

  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-10-5")
    @db_path = File.join(@tmp_dir, "test.db")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    File.write(File.join(@config_dir, "config.yml"), YAML.dump("db_path" => @db_path))
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_create_with_invalid_json_exits_nonzero
    data, exit_code = run_command("create", stdin: "{invalid json")

    refute_equal 0, exit_code, "Exit code should be non-zero for invalid JSON"
    assert data.key?("error"), "Output should be a JSON error object"
    assert_match(/json/i, data["error"], "Error should mention JSON")
  end

  def test_create_with_invalid_json_output_is_valid_json
    raw_stdout, _stderr, _status = run_command_raw("create", stdin: "{invalid json")

    assert_silent do
      JSON.parse(raw_stdout)
    end
  end

  def test_addend_with_invalid_json_exits_nonzero
    # Bootstrap the DB and create an article to have a valid ID
    env = { "AGENT_TOME_CONFIG_DIR" => @config_dir, "RUBYLIB" => LIB_PATH }
    run_command_raw("create", stdin: JSON.generate("description" => "Test", "body" => "Body"), env: env)

    # Now test invalid JSON on addend (we can use "ANYID" — the invalid JSON
    # error fires before any article lookup)
    data, exit_code = run_command("addend", "ANYID", stdin: "{invalid json")

    refute_equal 0, exit_code
    assert data.key?("error")
    assert_match(/json/i, data["error"])
  end

  def test_consolidate_with_invalid_json_exits_nonzero
    data, exit_code = run_command("consolidate", "ANYID", stdin: "{invalid json")

    refute_equal 0, exit_code
    assert data.key?("error")
    assert_match(/json/i, data["error"])
  end

  private

  def run_command(*args, stdin: nil, env: nil)
    env ||= { "AGENT_TOME_CONFIG_DIR" => @config_dir, "RUBYLIB" => LIB_PATH }
    raw_stdout, _stderr, status = run_command_raw(*args, stdin: stdin, env: env)
    data = JSON.parse(raw_stdout)
    [data, status.exitstatus]
  end

  def run_command_raw(*args, stdin: nil, env: nil)
    env ||= { "AGENT_TOME_CONFIG_DIR" => @config_dir, "RUBYLIB" => LIB_PATH }
    cmd = [RbConfig.ruby, BIN_PATH] + args
    Open3.capture3(env, *cmd, stdin_data: stdin || "")
  end
end
