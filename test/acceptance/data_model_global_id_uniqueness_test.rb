require "test_helper"
require "fileutils"
require "tmpdir"

# AT-11.1: Global IDs are unique within each table
# Schema-level integration test — verifies the unique DB constraint fires when
# a duplicate global_id is inserted into any table that carries one.
class DataModelGlobalIdUniquenessTest < Minitest::Test
  TABLES_WITH_GLOBAL_ID = %w[articles entries web_sources file_sources].freeze

  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-11-1")
    @db_path = File.join(@tmp_dir, "test.db")
    Agent::Tome::Database.connect!(@db_path)
  end

  def teardown
    Agent::Tome::Database.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_articles_global_id_unique_index_exists
    assert_unique_index_on("articles", "global_id")
  end

  def test_entries_global_id_unique_index_exists
    assert_unique_index_on("entries", "global_id")
  end

  def test_web_sources_global_id_unique_index_exists
    assert_unique_index_on("web_sources", "global_id")
  end

  def test_file_sources_global_id_unique_index_exists
    assert_unique_index_on("file_sources", "global_id")
  end

  def test_duplicate_article_global_id_raises_constraint_violation
    now = Time.now.utc.iso8601
    conn = ActiveRecord::Base.connection
    conn.execute(<<~SQL)
      INSERT INTO articles (global_id, description, created_at) VALUES ('AAAAAAA', 'First', '#{now}')
    SQL
    assert_raises(ActiveRecord::RecordNotUnique) do
      conn.execute(<<~SQL)
        INSERT INTO articles (global_id, description, created_at) VALUES ('AAAAAAA', 'Duplicate', '#{now}')
      SQL
    end
  end

  def test_duplicate_entry_global_id_raises_constraint_violation
    now = Time.now.utc.iso8601
    conn = ActiveRecord::Base.connection
    article_id = conn.insert(<<~SQL)
      INSERT INTO articles (global_id, description, created_at) VALUES ('BBBBBBB', 'Article', '#{now}')
    SQL
    conn.execute(<<~SQL)
      INSERT INTO entries (global_id, article_id, body, created_at) VALUES ('CCCCCCC', #{article_id}, 'Body', '#{now}')
    SQL
    assert_raises(ActiveRecord::RecordNotUnique) do
      conn.execute(<<~SQL)
        INSERT INTO entries (global_id, article_id, body, created_at) VALUES ('CCCCCCC', #{article_id}, 'Dup', '#{now}')
      SQL
    end
  end

  def test_duplicate_web_source_global_id_raises_constraint_violation
    now = Time.now.utc.iso8601
    conn = ActiveRecord::Base.connection
    conn.execute(<<~SQL)
      INSERT INTO web_sources (global_id, url, created_at) VALUES ('DDDDDDD', 'https://a.example.com', '#{now}')
    SQL
    assert_raises(ActiveRecord::RecordNotUnique) do
      conn.execute(<<~SQL)
        INSERT INTO web_sources (global_id, url, created_at) VALUES ('DDDDDDD', 'https://b.example.com', '#{now}')
      SQL
    end
  end

  def test_duplicate_file_source_global_id_raises_constraint_violation
    now = Time.now.utc.iso8601
    conn = ActiveRecord::Base.connection
    conn.execute(<<~SQL)
      INSERT INTO file_sources (global_id, path, system_name, created_at) VALUES ('EEEEEEE', '/a/path', 'sys1', '#{now}')
    SQL
    assert_raises(ActiveRecord::RecordNotUnique) do
      conn.execute(<<~SQL)
        INSERT INTO file_sources (global_id, path, system_name, created_at) VALUES ('EEEEEEE', '/b/path', 'sys2', '#{now}')
      SQL
    end
  end

  private

  def assert_unique_index_on(table, column)
    indexes = ActiveRecord::Base.connection.indexes(table)
    unique_index = indexes.find { |idx| idx.columns == [column] && idx.unique }
    assert unique_index, "Expected a unique index on #{table}.#{column}, but none found"
  end
end
