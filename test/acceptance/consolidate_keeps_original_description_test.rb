require "test_helper"

# AT-6.5: Consolidation without description keeps original
class ConsolidateKeepsOriginalDescriptionTest < Minitest::Test
  include TomeDsl

  def test_consolidation_keeps_original_description_when_not_provided
    create_result = create_article!(
      description: "Original description",
      body: "Original content."
    )
    original_id = create_result.article_global_id

    result = tome.consolidate(original_id, body: "New merged content")
    assert_success result, "Consolidate failed: #{result.error_message}"

    fetch_result = tome.fetch(result.new_article_global_id)
    assert_success fetch_result
    assert_equal "Original description", fetch_result.data["description"]
  end
end
