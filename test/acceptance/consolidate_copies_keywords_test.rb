require "test_helper"

# AT-6.2: Consolidation copies keywords
class ConsolidateCopiesKeywordsTest < Minitest::Test
  include TomeDsl

  def test_consolidation_copies_keywords_to_new_article
    create_result = tome.create(
      description: "Ruby GC and performance",
      body: "Ruby uses mark-and-sweep.",
      keywords: ["ruby", "gc", "performance"]
    )
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    original_id = create_result.article_global_id

    result = tome.consolidate(original_id, body: "Consolidated content.")
    assert result.success?, "Consolidate failed: #{result.error_message}"

    new_id = result.new_article_global_id

    fetch_result = tome.fetch(new_id)
    assert fetch_result.success?

    keywords = fetch_result.data["keywords"].sort
    assert_equal ["gc", "performance", "ruby"], keywords
  end
end
