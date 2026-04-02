require "test_helper"

# AT-2.10: Related article ID that does not exist is rejected
class RelatedArticleIdNotFoundTest < Minitest::Test
  include TomeDsl

  def test_nonexistent_related_article_id_is_rejected
    result = tome.create(
      description: "Article referencing nonexistent",
      body: "Some content",
      related_article_ids: ["INVALID"]
    )

    refute result.success?
    assert_match(/not found/i, result.error_message)
  end

  def test_no_records_created_when_related_id_invalid
    result = tome.create(
      description: "Article referencing nonexistent",
      body: "Some content",
      related_article_ids: ["INVALID"]
    )

    refute result.success?
    assert_equal 0, Agent::Tome::Article.count, "No article should be created"
    assert_equal 0, Agent::Tome::Entry.count, "No entry should be created"
  end
end
