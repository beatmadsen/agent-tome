require "test_helper"

# AT-6.6c: Consolidation rejects description exceeding 350 characters
class ConsolidateDescriptionTooLongTest < Minitest::Test
  include TomeDsl

  def test_consolidation_rejects_description_exceeding_350_characters
    create_result = create_article!(description: "An article", body: "Content.")
    article_id = create_result.article_global_id

    long_description = "x" * 351
    result = tome.consolidate(article_id, body: "Consolidated content.", description: long_description)

    refute result.success?
    assert_match(/description/i, result.error_message)
  end
end
