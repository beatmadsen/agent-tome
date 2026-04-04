require "test_helper"

# AT-6.6: Consolidation requires body
class ConsolidateRequiresBodyTest < Minitest::Test
  include TomeDsl

  def test_consolidation_requires_body
    create_result = create_article!(description: "An article", body: "Content.")
    article_id = create_result.article_global_id

    result = tome.consolidate(article_id)

    refute result.success?
    assert_match(/body/i, result.error_message)
  end
end
