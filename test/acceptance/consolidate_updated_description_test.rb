require "test_helper"

# AT-6.4: Consolidation with updated description
class ConsolidateUpdatedDescriptionTest < Minitest::Test
  include TomeDsl

  def test_consolidation_uses_provided_description
    create_result = tome.create(
      description: "Old description",
      body: "Original content."
    )
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    original_id = create_result.article_global_id

    result = tome.consolidate(original_id, body: "New merged content", description: "Updated description")
    assert result.success?, "Consolidate failed: #{result.error_message}"

    fetch_result = tome.fetch(result.new_article_global_id)
    assert fetch_result.success?
    assert_equal "Updated description", fetch_result.data["description"]
  end
end
