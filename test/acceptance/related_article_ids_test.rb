require "test_helper"

# AT-2.9: Related article IDs create ArticleReference records
class RelatedArticleIdsTest < Minitest::Test
  include TomeDsl

  def test_creates_article_reference_for_related_article_id
    existing = tome.create(description: "Existing article", body: "Some content")
    assert existing.success?, existing.error_message
    existing_id = existing.data["article_global_id"]

    result = tome.create(
      description: "New article referencing existing",
      body: "More content",
      related_article_ids: [existing_id]
    )

    assert result.success?, result.error_message

    assert_equal 1, Agent::Tome::ArticleReference.count,
                 "Expected one article_references row to be created"

    ref = Agent::Tome::ArticleReference.first
    new_article = Agent::Tome::Article.find_by!(global_id: result.data["article_global_id"])
    existing_article = Agent::Tome::Article.find_by!(global_id: existing_id)

    assert_equal new_article.id, ref.source_article_id,
                 "Expected the new article to be the source"
    assert_equal existing_article.id, ref.target_article_id,
                 "Expected the existing article to be the target"
  end
end
