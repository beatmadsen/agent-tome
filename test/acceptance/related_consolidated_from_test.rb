require "test_helper"

# AT-7.4: Related via ConsolidationLink (consolidated_from)
class RelatedConsolidatedFromTest < Minitest::Test
  include TomeDsl

  def test_consolidated_from_includes_old_article
    # Create article N (original)
    result_n = create_article!(description: "Article N original", body: "Original body")
    original_id = result_n.article_global_id

    # Consolidate — new article takes original ID, old article gets a new ID
    con_result = tome.consolidate(original_id, body: "Consolidated content")
    assert_success con_result, "Consolidate failed: #{con_result.error_message}"
    old_id = con_result.old_article_global_id

    # related on the new article (original_id) should have consolidated_from including the old article
    result = tome.related(original_id)
    assert_success result, "Related failed: #{result.error_message}"

    consolidated_from = result.data["consolidated_from"]
    assert_instance_of Array, consolidated_from

    ids = consolidated_from.map { |r| r["global_id"] }
    assert_includes ids, old_id, "consolidated_from should include the old (re-IDed) article"

    # The new article should not appear in consolidated_from
    refute_includes ids, original_id, "new article should not reference itself via consolidated_from"

    # Each result includes required fields
    entry = consolidated_from.find { |r| r["global_id"] == old_id }
    assert entry.key?("description"), "consolidated_from entry should have description"
    assert entry.key?("keywords"), "consolidated_from entry should have keywords"
    assert entry.key?("created_at"), "consolidated_from entry should have created_at"
    refute entry.key?("id"), "Internal id must not be exposed"
  end
end
