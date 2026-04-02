require "test_helper"

# AT-6.5: Consolidation without description keeps original
class ConsolidateKeepsOriginalDescriptionTest < Minitest::Test
  include TomeDsl

  def test_consolidation_keeps_original_description_when_not_provided
    create_result = tome.create(
      description: "Original description",
      body: "Original content."
    )
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    original_id = create_result.article_global_id

    result = tome.consolidate(original_id, body: "New merged content")
    assert result.success?, "Consolidate failed: #{result.error_message}"

    fetch_result = tome.fetch(result.new_article_global_id)
    assert fetch_result.success?
    assert_equal "Original description", fetch_result.data["description"]
  end
end
