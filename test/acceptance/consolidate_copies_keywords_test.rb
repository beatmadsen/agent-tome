require "test_helper"

# AT-6.2: Consolidation copies keywords
class ConsolidateCopiesKeywordsTest < Minitest::Test
  include TomeDsl

  def test_consolidation_copies_keywords_to_new_article
    create_result = create_article!(
      description: "Ruby GC and performance",
      body: "Ruby uses mark-and-sweep.",
      keywords: ["ruby", "gc", "performance"]
    )
    original_id = create_result.article_global_id

    result = tome.consolidate(original_id, body: "Consolidated content.")
    assert_success result, "Consolidate failed: #{result.error_message}"

    new_id = result.new_article_global_id

    fetch_result = tome.fetch(new_id)
    assert_success fetch_result

    keywords = fetch_result.data["keywords"].sort
    assert_equal ["gc", "performance", "ruby"], keywords
  end
end
