require "test_helper"

# AT-2.22: Self-referencing related_article_ids is rejected
class SelfReferencingRelatedArticleTest < Minitest::Test
  include TomeDsl

  def test_addend_with_self_reference_is_rejected
    create_result = create_article!(description: "Article A", body: "Content of A")

    article_id = create_result.article_global_id

    result = tome.addend(article_id, related_article_ids: [article_id])

    refute result.success?
    assert_match(/cannot reference itself/i, result.error_message)
  end
end
