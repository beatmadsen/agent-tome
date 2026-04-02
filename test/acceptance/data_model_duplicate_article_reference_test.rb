require "test_helper"
require "fileutils"
require "tmpdir"

# AT-11.5: Duplicate article reference is prevented
# Schema-level integration test — verifies unique constraint on
# article_references(source_article_id, target_article_id).
class DataModelDuplicateArticleReferenceTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-11-5")
    @db_path = File.join(@tmp_dir, "test.db")
    Agent::Tome::Database.connect!(@db_path)
  end

  def teardown
    Agent::Tome::Database.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_article_references_has_unique_index_on_source_and_target
    indexes = ActiveRecord::Base.connection.indexes("article_references")
    unique_index = indexes.find { |idx| idx.columns.sort == %w[source_article_id target_article_id] && idx.unique }
    assert unique_index, "Expected a unique index on article_references(source_article_id, target_article_id)"
  end

  def test_duplicate_article_reference_raises_constraint_violation
    now = Time.now.utc.iso8601
    conn = ActiveRecord::Base.connection

    source_id = conn.insert(<<~SQL)
      INSERT INTO articles (global_id, description, created_at) VALUES ('AAAAAAC', 'Source Article', '#{now}')
    SQL
    target_id = conn.insert(<<~SQL)
      INSERT INTO articles (global_id, description, created_at) VALUES ('BBBBBBC', 'Target Article', '#{now}')
    SQL

    conn.execute(<<~SQL)
      INSERT INTO article_references (source_article_id, target_article_id, created_at) VALUES (#{source_id}, #{target_id}, '#{now}')
    SQL

    assert_raises(ActiveRecord::RecordNotUnique) do
      conn.execute(<<~SQL)
        INSERT INTO article_references (source_article_id, target_article_id, created_at) VALUES (#{source_id}, #{target_id}, '#{now}')
      SQL
    end
  end
end
