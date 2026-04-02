require "test_helper"
require "fileutils"
require "tmpdir"

# AT-11.3: Duplicate keyword on same article is handled gracefully
# Schema-level integration test — verifies the unique constraint on
# article_keywords (article_id, keyword_id) prevents duplicate rows.
class DataModelDuplicateKeywordConstraintTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test-11-3")
    @db_path = File.join(@tmp_dir, "test.db")
    Agent::Tome::Database.connect!(@db_path)
  end

  def teardown
    Agent::Tome::Database.disconnect!
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def test_article_keywords_has_unique_index_on_article_id_and_keyword_id
    indexes = ActiveRecord::Base.connection.indexes("article_keywords")
    unique_index = indexes.find { |idx| idx.columns.sort == %w[article_id keyword_id] && idx.unique }
    assert unique_index, "Expected a unique index on article_keywords(article_id, keyword_id)"
  end

  def test_duplicate_article_keyword_raises_constraint_violation
    now = Time.now.utc.iso8601
    conn = ActiveRecord::Base.connection

    article_id = conn.insert(<<~SQL)
      INSERT INTO articles (global_id, description, created_at) VALUES ('AAAAAAA', 'Test Article', '#{now}')
    SQL
    keyword_id = conn.insert(<<~SQL)
      INSERT INTO keywords (term, created_at) VALUES ('ruby', '#{now}')
    SQL

    conn.execute(<<~SQL)
      INSERT INTO article_keywords (article_id, keyword_id, created_at) VALUES (#{article_id}, #{keyword_id}, '#{now}')
    SQL

    assert_raises(ActiveRecord::RecordNotUnique) do
      conn.execute(<<~SQL)
        INSERT INTO article_keywords (article_id, keyword_id, created_at) VALUES (#{article_id}, #{keyword_id}, '#{now}')
      SQL
    end
  end
end
