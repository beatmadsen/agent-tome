require "test_helper"
require "open3"

# AT-1.2: First run creates database and runs all migrations
class FirstRunCreatesDatabaseTest < Minitest::Test
  EXPECTED_TABLES = %w[
    articles entries keywords article_keywords
    web_sources file_sources entry_web_sources entry_file_sources
    article_references consolidation_links schema_migrations
  ].freeze

  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-1-2")
    @db_path = File.join(@tmp_dir, "test.db")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    File.write(File.join(@config_dir, "config.yml"), YAML.dump("db_path" => @db_path))
  end

  def teardown
    Agent::Tome::Database.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_creates_database_with_all_tables_and_search_exits_zero
    refute File.exist?(@db_path), "Precondition: database file must not exist before first run"

    config = Agent::Tome::Config.new(config_dir: @config_dir)
    config.load!
    Agent::Tome::Database.connect!(config.db_path)

    assert File.exist?(@db_path),
           "Database file should be created at the configured db_path"

    existing_tables = ActiveRecord::Base.connection.tables
    EXPECTED_TABLES.each do |table|
      assert_includes existing_tables, table,
                      "Table '#{table}' should exist after migrations run"
    end

    result = Agent::Tome::Commands::Search.new(keywords: ["ruby"], match: "any").call
    assert result.key?("results"), "Search should return a results key"
  end
end

# AT-1.3: Pending migrations are applied automatically on invocation
class PendingMigrationsAutoApplyTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-1-3")
    @db_path = File.join(@tmp_dir, "test.db")
    @migrations_dir = File.join(@tmp_dir, "migrations")
    FileUtils.mkdir_p(@migrations_dir)

    # Copy the real initial migrations to the temp dir (simulate "old gem version")
    Dir[File.join(Agent::Tome::Database::MIGRATIONS_PATH, "*.rb")].each do |f|
      FileUtils.cp(f, @migrations_dir)
    end

    Agent::Tome::Database.migrations_path = @migrations_dir
  end

  def teardown
    Agent::Tome::Database.migrations_path = nil
    Agent::Tome::Database.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_pending_migration_applied_automatically_on_next_invocation
    # Simulate old gem version: connect and run existing migrations
    Agent::Tome::Database.connect!(@db_path)

    initial_versions = ActiveRecord::Base.connection
      .select_values("SELECT version FROM schema_migrations ORDER BY version")

    refute_empty initial_versions, "Initial migrations should have run"

    # Simulate gem upgrade: add a new migration to the temp dir
    new_migration_path = File.join(@migrations_dir, "20250602000001_add_pending_test.rb")
    File.write(new_migration_path, <<~RUBY)
      class AddPendingTest < ActiveRecord::Migration[7.1]
        def change
          create_table :pending_migration_test do |t|
            t.string :marker, null: false
            t.datetime :created_at, null: false
          end
        end
      end
    RUBY

    # Simulate next CLI invocation: connect! auto-applies pending migrations
    Agent::Tome::Database.connect!(@db_path)

    tables = ActiveRecord::Base.connection.tables
    assert_includes tables, "pending_migration_test",
                    "Pending migration should be applied automatically on next invocation"

    all_versions = ActiveRecord::Base.connection
      .select_values("SELECT version FROM schema_migrations ORDER BY version")
    assert_includes all_versions, "20250602000001",
                    "New migration version should be recorded in schema_migrations"

    initial_versions.each do |v|
      assert_includes all_versions, v,
                      "Existing migration version #{v} should still be present in schema_migrations"
    end

    # Command should succeed after auto-migration
    result = Agent::Tome::Commands::Search.new(keywords: ["ruby"], match: "any").call
    assert result.key?("results"), "Command should succeed after pending migrations are applied"
  end
end

# AT-1.4: Migration state is tracked in the database
class MigrationStateTrackedInDatabaseTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-1-4")
    @db_path = File.join(@tmp_dir, "test.db")
  end

  def teardown
    Agent::Tome::Database.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_migrations_not_reapplied_and_each_version_recorded_once
    # First invocation: creates DB and runs all migrations
    Agent::Tome::Database.connect!(@db_path)

    versions_after_first = ActiveRecord::Base.connection
      .select_values("SELECT version FROM schema_migrations ORDER BY version")

    refute_empty versions_after_first, "Migrations should have run on first connect"

    # Second invocation: simulates running another command
    Agent::Tome::Database.connect!(@db_path)

    versions_after_second = ActiveRecord::Base.connection
      .select_values("SELECT version FROM schema_migrations ORDER BY version")

    assert_equal versions_after_first.sort, versions_after_second.sort,
                 "schema_migrations should be unchanged after second invocation"

    # Each version must appear exactly once
    versions_after_second.each do |version|
      count = ActiveRecord::Base.connection
        .select_value("SELECT COUNT(*) FROM schema_migrations WHERE version = '#{version}'")
        .to_i
      assert_equal 1, count,
                   "Version #{version} should appear exactly once in schema_migrations"
    end
  end
end

# AT-1.5: Missing config file produces a clear error
class MissingConfigFileErrorTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-1-5")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    # Config dir exists but config.yml is deliberately absent
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_missing_config_file_raises_config_error_with_clear_message
    config = Agent::Tome::Config.new(config_dir: @config_dir)
    error = assert_raises(Agent::Tome::ConfigError) { config.load! }
    assert_match(/config/i, error.message,
                 "Error should mention the config file, got: #{error.message.inspect}")
  end

  def test_missing_config_file_cli_exits_nonzero_with_json_error
    env = { "AGENT_TOME_CONFIG_DIR" => @config_dir, "RUBYLIB" => File.expand_path("../../lib", __dir__) }
    bin = File.expand_path("../../bin/agent-tome", __dir__)
    cmd = [RbConfig.ruby, bin, "search", "ruby"]

    stdout, _stderr, status = Open3.capture3(env, *cmd)

    refute_equal 0, status.exitstatus, "Exit code should be non-zero"
    parsed = JSON.parse(stdout)
    assert parsed.key?("error"), "Output should be a JSON error object"
    assert_match(/config/i, parsed["error"])
  end
end

# AT-1.6: Missing db_path in config produces a clear error
class MissingDbPathInConfigErrorTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-1-6")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    File.write(File.join(@config_dir, "config.yml"), YAML.dump({}))
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_missing_db_path_raises_config_error_with_clear_message
    config = Agent::Tome::Config.new(config_dir: @config_dir)
    error = assert_raises(Agent::Tome::ConfigError) { config.load! }
    assert_match(/db_path/i, error.message,
                 "Error should mention db_path, got: #{error.message.inspect}")
  end

  def test_missing_db_path_cli_exits_nonzero_with_json_error
    env = { "AGENT_TOME_CONFIG_DIR" => @config_dir, "RUBYLIB" => File.expand_path("../../lib", __dir__) }
    bin = File.expand_path("../../bin/agent-tome", __dir__)
    cmd = [RbConfig.ruby, bin, "search", "ruby"]

    stdout, _stderr, status = Open3.capture3(env, *cmd)

    refute_equal 0, status.exitstatus, "Exit code should be non-zero"
    parsed = JSON.parse(stdout)
    assert parsed.key?("error"), "Output should be a JSON error object"
    assert_match(/db_path/i, parsed["error"])
  end
end

# AT-1.7: Unwritable db_path produces a clear error
class UnwritableDbPathErrorTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-1-7")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    @db_path = "/root/no-access/tome.db"
    File.write(File.join(@config_dir, "config.yml"), YAML.dump("db_path" => @db_path))
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_unwritable_db_path_raises_database_error
    skip "Test must not run as root" if Process.uid == 0

    config = Agent::Tome::Config.new(config_dir: @config_dir)
    config.load!
    error = assert_raises(Agent::Tome::DatabaseError) { Agent::Tome::Database.connect!(config.db_path) }
    assert_match(/not writable|writable/i, error.message,
                 "Error should mention the path is not writable, got: #{error.message.inspect}")
  end

  def test_unwritable_db_path_cli_exits_nonzero_with_json_error
    skip "Test must not run as root" if Process.uid == 0

    env = { "AGENT_TOME_CONFIG_DIR" => @config_dir, "RUBYLIB" => File.expand_path("../../lib", __dir__) }
    bin = File.expand_path("../../bin/agent-tome", __dir__)
    cmd = [RbConfig.ruby, bin, "search", "ruby"]

    stdout, _stderr, status = Open3.capture3(env, *cmd)

    refute_equal 0, status.exitstatus, "Exit code should be non-zero"
    parsed = JSON.parse(stdout)
    assert parsed.key?("error"), "Output should be a JSON error object"
    assert_match(/writable/i, parsed["error"])
  end
end

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
