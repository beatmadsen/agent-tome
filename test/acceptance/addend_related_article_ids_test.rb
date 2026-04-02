require "test_helper"

# AT-3.9: Related article IDs on addendum
class AddendRelatedArticleIdsTest < Minitest::Test
  include TomeDsl

  def test_addend_creates_article_reference
    article_a = tome.create(description: "Article A", body: "Content A")
    assert article_a.success?, article_a.error_message
    a_id = article_a.data["article_global_id"]

    article_b = tome.create(description: "Article B", body: "Content B")
    assert article_b.success?, article_b.error_message
    b_id = article_b.data["article_global_id"]

    result = tome.addend(a_id, related_article_ids: [b_id])

    assert result.success?, result.error_message

    ref = Agent::Tome::ArticleReference.find_by(
      source_article: Agent::Tome::Article.find_by!(global_id: a_id),
      target_article: Agent::Tome::Article.find_by!(global_id: b_id)
    )
    refute_nil ref, "Expected an article_references row linking A to B"
  end
end
