require "test_helper"

# AT-13.2: Create, consolidate, fetch lifecycle
class WorkflowConsolidateFetchTest < Minitest::Test
  include TomeDsl

  def test_consolidate_fetch_lifecycle
    # Step 1: Create article with 3 addenda (1 original + 2 addenda = 3 entries total)
    create_result = create_article!(
      description: "Ruby GC internals",
      body: "Mark and sweep is the baseline GC.",
      keywords: ["ruby", "gc"]
    )
    original_id = create_result.article_global_id

    addend1 = tome.addend(original_id, body: "Generational GC added in Ruby 2.1.")
    assert_success addend1, "Addend 1 failed: #{addend1.error_message}"

    addend2 = tome.addend(original_id, body: "Incremental GC added in Ruby 2.2.")
    assert_success addend2, "Addend 2 failed: #{addend2.error_message}"

    addend3 = tome.addend(original_id, body: "GC.compact introduced in Ruby 2.7.")
    assert_success addend3, "Addend 3 failed: #{addend3.error_message}"

    # Step 2: Consolidate — new article takes over original ID, old gets a new ID
    consolidate_result = tome.consolidate(
      original_id,
      body: "Ruby GC evolved from mark-and-sweep to generational (2.1), incremental (2.2), and compacting (2.7)."
    )
    assert_success consolidate_result, "Consolidate failed: #{consolidate_result.error_message}"

    new_article_id = consolidate_result.new_article_global_id
    old_article_id = consolidate_result.old_article_global_id

    assert_equal original_id, new_article_id, "New article should inherit the original ID"
    refute_equal original_id, old_article_id, "Old article should have a different ID now"
    assert_global_id old_article_id

    # Step 3: Fetch via original ID — returns the consolidated article with consolidated_from
    fetch_new = tome.fetch(original_id)
    assert_success fetch_new, "Fetch new failed: #{fetch_new.error_message}"

    new_data = fetch_new.data
    assert_equal original_id, new_data["global_id"]
    assert_equal 1, new_data["entries"].length, "Consolidated article should have exactly one entry"
    assert_equal(
      "Ruby GC evolved from mark-and-sweep to generational (2.1), incremental (2.2), and compacting (2.7).",
      new_data["entries"][0]["body"]
    )

    consolidated_from = new_data["consolidated_from"]
    refute_nil consolidated_from, "consolidated_from must be present"
    assert_equal old_article_id, consolidated_from["global_id"]
    assert_equal "Ruby GC internals", consolidated_from["description"]

    # Step 4: Fetch old article by its new ID — returns all original entries
    fetch_old = tome.fetch(old_article_id)
    assert_success fetch_old, "Fetch old failed: #{fetch_old.error_message}"

    old_data = fetch_old.data
    assert_equal old_article_id, old_data["global_id"]
    assert_equal 4, old_data["entries"].length, "Old article should have all 4 original entries"
    assert_equal "Mark and sweep is the baseline GC.", old_data["entries"][0]["body"]
    assert_equal "GC.compact introduced in Ruby 2.7.", old_data["entries"][3]["body"]

    # Step 5: Related on original ID — consolidated_from includes the old article
    related_result = tome.related(original_id)
    assert_success related_result, "Related failed: #{related_result.error_message}"

    related_data = related_result.data
    consolidated_from_related = related_data["consolidated_from"]
    refute_nil consolidated_from_related
    old_ids = consolidated_from_related.map { |r| r["global_id"] }
    assert_includes old_ids, old_article_id, "consolidated_from should include the old article"
  end
end
