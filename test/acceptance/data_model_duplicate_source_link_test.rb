require "test_helper"
require "fileutils"
require "tmpdir"

# AT-11.4: Duplicate source link on same entry is prevented
# Schema-level integration test — verifies unique constraints on
# entry_web_sources(entry_id, web_source_id) and entry_file_sources(entry_id, file_source_id).
class DataModelDuplicateSourceLinkTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-11-4")
    @db_path = File.join(@tmp_dir, "test.db")
    Agent::Tome::Database.connect!(@db_path)
  end

  def teardown
    Agent::Tome::Database.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_entry_web_sources_has_unique_index_on_entry_id_and_web_source_id
    indexes = ActiveRecord::Base.connection.indexes("entry_web_sources")
    unique_index = indexes.find { |idx| idx.columns.sort == %w[entry_id web_source_id] && idx.unique }
    assert unique_index, "Expected a unique index on entry_web_sources(entry_id, web_source_id)"
  end

  def test_entry_file_sources_has_unique_index_on_entry_id_and_file_source_id
    indexes = ActiveRecord::Base.connection.indexes("entry_file_sources")
    unique_index = indexes.find { |idx| idx.columns.sort == %w[entry_id file_source_id] && idx.unique }
    assert unique_index, "Expected a unique index on entry_file_sources(entry_id, file_source_id)"
  end

  def test_duplicate_entry_web_source_raises_constraint_violation
    now = Time.now.utc.iso8601
    conn = ActiveRecord::Base.connection

    article_id = conn.insert(<<~SQL)
      INSERT INTO articles (global_id, description, created_at) VALUES ('AAAAAAB', 'Test Article', '#{now}')
    SQL
    entry_id = conn.insert(<<~SQL)
      INSERT INTO entries (global_id, article_id, created_at) VALUES ('BBBBBBB', #{article_id}, '#{now}')
    SQL
    web_source_id = conn.insert(<<~SQL)
      INSERT INTO web_sources (global_id, url, created_at) VALUES ('CCCCCCC', 'https://example.com', '#{now}')
    SQL

    conn.execute(<<~SQL)
      INSERT INTO entry_web_sources (entry_id, web_source_id, created_at) VALUES (#{entry_id}, #{web_source_id}, '#{now}')
    SQL

    assert_raises(ActiveRecord::RecordNotUnique) do
      conn.execute(<<~SQL)
        INSERT INTO entry_web_sources (entry_id, web_source_id, created_at) VALUES (#{entry_id}, #{web_source_id}, '#{now}')
      SQL
    end
  end

  def test_duplicate_entry_file_source_raises_constraint_violation
    now = Time.now.utc.iso8601
    conn = ActiveRecord::Base.connection

    article_id = conn.insert(<<~SQL)
      INSERT INTO articles (global_id, description, created_at) VALUES ('DDDDDDD', 'Test Article 2', '#{now}')
    SQL
    entry_id = conn.insert(<<~SQL)
      INSERT INTO entries (global_id, article_id, created_at) VALUES ('EEEEEEE', #{article_id}, '#{now}')
    SQL
    file_source_id = conn.insert(<<~SQL)
      INSERT INTO file_sources (global_id, path, system_name, created_at) VALUES ('FFFFFFF', '/home/user/doc.pdf', 'work-laptop', '#{now}')
    SQL

    conn.execute(<<~SQL)
      INSERT INTO entry_file_sources (entry_id, file_source_id, created_at) VALUES (#{entry_id}, #{file_source_id}, '#{now}')
    SQL

    assert_raises(ActiveRecord::RecordNotUnique) do
      conn.execute(<<~SQL)
        INSERT INTO entry_file_sources (entry_id, file_source_id, created_at) VALUES (#{entry_id}, #{file_source_id}, '#{now}')
      SQL
    end
  end
end
