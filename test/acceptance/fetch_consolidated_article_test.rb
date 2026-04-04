require "test_helper"

# AT-5.4: Fetch consolidated article includes consolidated_from
class FetchConsolidatedArticleTest < Minitest::Test
  include TomeDsl

  def test_fetch_consolidated_article_includes_consolidated_from
    # Create an article and add an addendum
    create_result = create_article!(
      description: "Ruby GC internals",
      body: "Mark and sweep basics.",
      keywords: ["ruby", "gc"]
    )
    original_id = create_result.article_global_id

    addend_result = tome.addend(original_id, body: "Generational GC added in 2.1.")
    assert_success addend_result, "Addend failed: #{addend_result.error_message}"

    # Consolidate
    consolidate_result = tome.consolidate(original_id, body: "Consolidated: Ruby uses generational mark-and-sweep GC.")
    assert_success consolidate_result, "Consolidate failed: #{consolidate_result.error_message}"

    new_article_id = consolidate_result.new_article_global_id
    old_article_id = consolidate_result.old_article_global_id

    # The new article took over the original ID
    assert_equal original_id, new_article_id

    # Fetch the new consolidated article via the original ID
    fetch_result = tome.fetch(original_id)
    assert_success fetch_result, "Fetch failed: #{fetch_result.error_message}"

    data = fetch_result.data
    assert_equal original_id, data["global_id"]

    # consolidated_from must be present
    consolidated_from = data["consolidated_from"]
    refute_nil consolidated_from, "consolidated_from should be present for a consolidated article"
    assert_equal old_article_id, consolidated_from["global_id"]
    refute_nil consolidated_from["description"]
    assert_equal "Ruby GC internals", consolidated_from["description"]

    # The consolidated article has one entry (the consolidated body)
    assert_equal 1, data["entries"].length
    assert_equal "Consolidated: Ruby uses generational mark-and-sweep GC.", data["entries"][0]["body"]
  end

  def test_fetch_non_consolidated_article_has_no_consolidated_from
    create_result = create_article!(
      description: "Plain article",
      body: "Some content."
    )

    fetch_result = tome.fetch(create_result.article_global_id)
    assert_success fetch_result

    data = fetch_result.data
    assert_nil data["consolidated_from"], "consolidated_from should not be present for a plain article"
  end
end
