require "test_helper"

# AT-7.3b: Related via ArticleReference (referenced_by)
class RelatedReferencedByTest < Minitest::Test
  include TomeDsl

  def test_referenced_by_includes_source_article
    result_b = tome.create(description: "Article B", body: "Body B")
    assert result_b.success?, "Setup failed: #{result_b.error_message}"
    id_b = result_b.article_global_id

    # A is source, B is target
    result_a = tome.create(
      description: "Article A",
      body: "Body A",
      related_article_ids: [id_b]
    )
    assert result_a.success?, "Setup failed: #{result_a.error_message}"
    id_a = result_a.article_global_id

    result = tome.related(id_b)
    assert result.success?, "Related failed: #{result.error_message}"

    referenced_by = result.data["referenced_by"]
    assert_instance_of Array, referenced_by

    ids = referenced_by.map { |r| r["global_id"] }
    assert_includes ids, id_a, "referenced_by should include Article A (the source)"

    # references_to should not include Article A
    references_to = result.data["references_to"]
    refute_includes references_to.map { |r| r["global_id"] }, id_a,
      "references_to should not include Article A"

    # Each result includes required fields
    entry = referenced_by.find { |r| r["global_id"] == id_a }
    assert entry.key?("description")
    assert entry.key?("keywords")
    assert entry.key?("created_at")
    refute entry.key?("id"), "Internal id must not be exposed"
  end
end
