require "test_helper"

# AT-6.8: Fetching old article by its new ID still works
class ConsolidateFetchOldArticleTest < Minitest::Test
  include TomeDsl

  def test_fetching_old_article_by_new_id_returns_original_entries
    # Create article with two entries
    create_result = create_article!(
      description: "Ruby GC internals",
      body: "Mark and sweep basics.",
      keywords: ["ruby", "gc"]
    )
    original_id = create_result.article_global_id

    addend_result = tome.addend(original_id, body: "Generational GC added in 2.1.")
    assert_success addend_result, "Addend failed: #{addend_result.error_message}"

    # Consolidate — old article is re-IDed, new article takes over original_id
    consolidate_result = tome.consolidate(
      original_id,
      body: "Consolidated content merging all entries."
    )
    assert_success consolidate_result, "Consolidate failed: #{consolidate_result.error_message}"

    new_article_id = consolidate_result.new_article_global_id
    old_article_id = consolidate_result.old_article_global_id

    assert_equal original_id, new_article_id, "New article should take over the original ID"
    refute_equal original_id, old_article_id, "Old article should have a different (new) ID"

    # Fetch old article via its newly assigned global_id
    fetch_result = tome.fetch(old_article_id)
    assert_success fetch_result, "Fetch of old article failed: #{fetch_result.error_message}"

    data = fetch_result.data
    assert_equal old_article_id, data["global_id"]

    # Old article retains all its original entries
    assert_equal 2, data["entries"].length, "Old article should have both original entries"
    assert_equal "Mark and sweep basics.", data["entries"][0]["body"]
    assert_equal "Generational GC added in 2.1.", data["entries"][1]["body"]

    # Old article description is preserved
    assert_equal "Ruby GC internals", data["description"]
  end
end
