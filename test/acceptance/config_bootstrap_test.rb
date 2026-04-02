require "test_helper"

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
