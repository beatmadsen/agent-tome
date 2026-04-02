require "test_helper"
require "open3"

# AT-10.7: Empty stdin is rejected
# When agent-tome create receives empty input (e.g., piped from /dev/null)
# Then exit code is non-zero, JSON error about missing input.
class EmptyStdinTest < Minitest::Test
  BIN_PATH = File.expand_path("../../bin/agent-tome", __dir__)
  LIB_PATH = File.expand_path("../../lib", __dir__)

  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-10-7")
    @db_path = File.join(@tmp_dir, "test.db")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    File.write(File.join(@config_dir, "config.yml"), YAML.dump("db_path" => @db_path))
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_create_with_empty_stdin_exits_nonzero
    data, exit_code = run_command("create", stdin: "")

    refute_equal 0, exit_code, "Exit code should be non-zero for empty stdin"
    assert data.key?("error"), "Output should be a JSON error object"
  end

  def test_create_with_empty_stdin_output_is_valid_json
    raw_stdout, _stderr, _status = run_command_raw("create", stdin: "")

    JSON.parse(raw_stdout) # raises if invalid
  end

  def test_create_with_whitespace_only_stdin_exits_nonzero
    data, exit_code = run_command("create", stdin: "   \n  ")

    refute_equal 0, exit_code, "Exit code should be non-zero for whitespace-only stdin"
    assert data.key?("error"), "Output should be a JSON error object"
  end

  def test_addend_with_empty_stdin_exits_nonzero
    data, exit_code = run_command("addend", "ANYID", stdin: "")

    refute_equal 0, exit_code
    assert data.key?("error")
  end

  def test_consolidate_with_empty_stdin_exits_nonzero
    data, exit_code = run_command("consolidate", "ANYID", stdin: "")

    refute_equal 0, exit_code
    assert data.key?("error")
  end

  private

  def run_command(*args, stdin: nil)
    env = { "AGENT_TOME_CONFIG_DIR" => @config_dir, "RUBYLIB" => LIB_PATH }
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
