require "test_helper"

# AT-6.7: Fetching via original ID after consolidation returns new article
class ConsolidateFetchOriginalIdTest < Minitest::Test
  include TomeDsl

  def test_fetching_original_id_returns_new_consolidated_article
    # Create article with an addendum so it has history worth consolidating
    create_result = create_article!(
      description: "Original article description",
      body: "Original first entry content.",
      keywords: ["ruby"]
    )
    original_id = create_result.article_global_id

    addend_result = tome.addend(original_id, body: "Additional finding.")
    assert_success addend_result, "Addend failed: #{addend_result.error_message}"

    # Consolidate — new article takes over the original global_id
    consolidate_result = tome.consolidate(
      original_id,
      body: "Merged consolidated content from all entries."
    )
    assert_success consolidate_result, "Consolidate failed: #{consolidate_result.error_message}"

    new_article_id = consolidate_result.new_article_global_id
    old_article_id = consolidate_result.old_article_global_id

    # The new article has the original ID
    assert_equal original_id, new_article_id
    refute_equal original_id, old_article_id

    # Fetch via the original ID — should return the NEW consolidated article
    fetch_result = tome.fetch(original_id)
    assert_success fetch_result, "Fetch failed: #{fetch_result.error_message}"

    data = fetch_result.data

    # The global_id in the response matches the original ID
    assert_equal original_id, data["global_id"]

    # It contains the consolidated (new) body, not the original entries
    assert_equal 1, data["entries"].length, "New consolidated article should have exactly one entry"
    assert_equal "Merged consolidated content from all entries.", data["entries"][0]["body"]

    # The consolidated_from field points to the old article
    consolidated_from = data["consolidated_from"]
    refute_nil consolidated_from, "consolidated_from must be present"
    assert_equal old_article_id, consolidated_from["global_id"]
    assert_equal "Original article description", consolidated_from["description"]
  end
end
