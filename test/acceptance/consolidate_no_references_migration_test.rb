require "test_helper"

# AT-6.3: Consolidation does not migrate ArticleReferences
class ConsolidateNoReferencesMigrationTest < Minitest::Test
  include TomeDsl

  def test_article_references_stay_with_old_article_after_consolidation
    # Create article Y (the target of the reference)
    y_result = create_article!(description: "Article Y", body: "Content of Y.")
    y_id = y_result.article_global_id

    # Create article X with a reference to Y
    x_result = create_article!(
      description: "Article X",
      body: "Content of X.",
      related_article_ids: [y_id]
    )
    original_x_id = x_result.article_global_id

    # Consolidate X
    consolidate_result = tome.consolidate(original_x_id, body: "Consolidated X content.")
    assert_success consolidate_result, "Consolidate failed: #{consolidate_result.error_message}"

    new_article_id = consolidate_result.new_article_global_id
    old_article_id = consolidate_result.old_article_global_id

    # new_article took over original_x_id
    assert_equal original_x_id, new_article_id

    # The new article should have NO references_to (ArticleReferences were not migrated)
    new_related = tome.related(new_article_id)
    assert_success new_related
    assert_empty new_related.data["references_to"],
      "New article should have no references_to, but got: #{new_related.data["references_to"].inspect}"

    # The old article (re-IDed) should still have its reference to Y
    old_related = tome.related(old_article_id)
    assert_success old_related
    old_refs_to = old_related.data["references_to"]
    assert_equal 1, old_refs_to.size,
      "Old article should still have its reference to Y, but got: #{old_refs_to.inspect}"
    assert_equal y_id, old_refs_to.first["global_id"]
  end
end
