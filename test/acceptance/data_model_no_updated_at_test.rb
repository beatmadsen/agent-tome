require "test_helper"
require "fileutils"
require "tmpdir"

# AT-11.2: No records have updated_at
# Verifies that no table in the schema has an updated_at column.
class DataModelNoUpdatedAtTest < Minitest::Test
  ALL_TABLES = %w[
    articles
    entries
    keywords
    article_keywords
    web_sources
    file_sources
    entry_web_sources
    entry_file_sources
    article_references
    consolidation_links
  ].freeze

  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-11-2")
    @db_path = File.join(@tmp_dir, "test.db")
    Agent::Tome::Database.connect!(@db_path)
  end

  def teardown
    Agent::Tome::Database.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  ALL_TABLES.each do |table|
    define_method(:"test_#{table}_has_no_updated_at_column") do
      columns = ActiveRecord::Base.connection.columns(table).map(&:name)
      refute_includes columns, "updated_at",
        "Table '#{table}' should not have an updated_at column"
    end
  end
end
