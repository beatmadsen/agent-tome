require "test_helper"

# AT-7.3: Related via ArticleReference (references_to)
class RelatedReferencesToTest < Minitest::Test
  include TomeDsl

  def test_references_to_includes_target_article
    result_a = create_article!(description: "Article A", body: "Body A")
    id_a = result_a.article_global_id

    result_b = create_article!(
      description: "Article B",
      body: "Body B",
      keywords: ["ruby"],
      related_article_ids: [id_a]
    )
    id_b = result_b.article_global_id

    result = tome.related(id_b)
    assert_success result, "Related failed: #{result.error_message}"

    references_to = result.data["references_to"]
    assert_instance_of Array, references_to

    ids = references_to.map { |r| r["global_id"] }
    assert_includes ids, id_a, "references_to should include Article A"

    # referenced_by should not include Article A (A is the target, not source)
    referenced_by = result.data["referenced_by"]
    refute_includes referenced_by.map { |r| r["global_id"] }, id_a

    # Each result includes required fields
    entry = references_to.find { |r| r["global_id"] == id_a }
    assert entry.key?("description")
    assert entry.key?("keywords")
    assert entry.key?("created_at")
    refute entry.key?("id"), "Internal id must not be exposed"
  end
end
