require "test_helper"

# AT-6.1: Basic consolidation
class ConsolidateBasicTest < Minitest::Test
  include TomeDsl

  def test_basic_consolidation
    # Create an article
    create_result = tome.create(
      description: "Ruby GC basics",
      body: "Ruby uses mark-and-sweep."
    )
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    original_id = create_result.article_global_id

    # Consolidate it
    result = tome.consolidate(original_id, body: "Consolidated content combining all entries.")
    assert result.success?, "Consolidate failed: #{result.error_message}"

    new_id = result.new_article_global_id
    old_id = result.old_article_global_id

    # New article takes over the original global_id
    assert_equal original_id, new_id

    # Old article has a different, newly generated global_id
    refute_equal original_id, old_id
    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\z/, old_id)

    # Both IDs returned are valid base58 7-char strings
    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\z/, new_id)

    # Verify the new article exists with the original global_id
    fetch_new = tome.fetch(new_id)
    assert fetch_new.success?
    assert_equal 1, fetch_new.data["entries"].length
    assert_equal "Consolidated content combining all entries.", fetch_new.data["entries"][0]["body"]

    # Verify the old article exists with the new global_id
    fetch_old = tome.fetch(old_id)
    assert fetch_old.success?
    assert_equal "Ruby GC basics", fetch_old.data["description"]

    # Consolidation link exists: verified via consolidated_from in the new article's fetch
    consolidated_from = fetch_new.data["consolidated_from"]
    refute_nil consolidated_from
    assert_equal old_id, consolidated_from["global_id"]
  end
end
