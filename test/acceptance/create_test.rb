require "test_helper"

BASE58_PATTERN = /\A[1-9A-HJ-NP-Za-km-z]{7}\z/

# AT-2.1: Minimal article creation
class MinimalArticleCreationTest < Minitest::Test
  include TomeDsl

  def test_creates_article_with_description_and_body
    result = tome.create(
      description: "How Ruby GC works",
      body: "Ruby uses a mark-and-sweep garbage collector."
    )

    assert result.success?, "Expected success but got error: #{result.error_message}"

    assert_match BASE58_PATTERN, result.article_global_id,
                 "article_global_id should be a 7-character base58 string"
    assert_match BASE58_PATTERN, result.entry_global_id,
                 "entry_global_id should be a 7-character base58 string"
    refute_equal result.article_global_id, result.entry_global_id,
                 "article_global_id and entry_global_id should be different"

    assert_empty result.data["web_source_global_ids"],
                 "No web source IDs should be in output for minimal creation"
    assert_empty result.data["file_source_global_ids"],
                 "No file source IDs should be in output for minimal creation"

    article = Agent::Tome::Article.find_by(global_id: result.article_global_id)
    refute_nil article, "Article should exist in the database"
    assert_equal "How Ruby GC works", article.description
    refute_nil article.created_at, "created_at should be set on article"

    assert_equal 1, article.entries.count, "Article should have exactly one entry"
    entry = article.entries.first
    assert_equal "Ruby uses a mark-and-sweep garbage collector.", entry.body
    assert_equal result.entry_global_id, entry.global_id
    refute_nil entry.created_at, "created_at should be set on entry"
  end
end
