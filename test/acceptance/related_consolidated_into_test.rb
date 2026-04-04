require "test_helper"

# AT-7.5: Related via ConsolidationLink (consolidated_into)
class RelatedConsolidatedIntoTest < Minitest::Test
  include TomeDsl

  def test_consolidated_into_includes_new_article
    # Create article O (original), then consolidate so O gets a new ID
    result_o = create_article!(description: "Article O original", body: "Original body")
    original_id = result_o.article_global_id

    # Consolidate — new article takes original_id, old article gets a new ID
    con_result = tome.consolidate(original_id, body: "Consolidated content")
    assert_success con_result, "Consolidate failed: #{con_result.error_message}"
    new_id = con_result.new_article_global_id
    old_id = con_result.old_article_global_id

    # related on the OLD article should have consolidated_into including the new article
    result = tome.related(old_id)
    assert_success result, "Related failed: #{result.error_message}"

    consolidated_into = result.data["consolidated_into"]
    assert_instance_of Array, consolidated_into

    ids = consolidated_into.map { |r| r["global_id"] }
    assert_includes ids, new_id, "consolidated_into should include the new (consolidated) article"

    # The old article should not appear in consolidated_into referencing itself
    refute_includes ids, old_id, "old article should not reference itself via consolidated_into"

    # Each result includes required fields
    entry = consolidated_into.find { |r| r["global_id"] == new_id }
    assert entry.key?("description"), "consolidated_into entry should have description"
    assert entry.key?("keywords"), "consolidated_into entry should have keywords"
    assert entry.key?("created_at"), "consolidated_into entry should have created_at"
    refute entry.key?("id"), "Internal id must not be exposed"
  end
end
