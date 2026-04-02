require "test_helper"

# AT-13.5: Cross-referencing articles (directional clarity)
class WorkflowCrossReferencingTest < Minitest::Test
  include TomeDsl

  def test_cross_referencing_directional_clarity
    # Step 1: Create article A
    result_a = tome.create(description: "Article A", body: "Body of article A.")
    assert result_a.success?, "Create A failed: #{result_a.error_message}"
    id_a = result_a.article_global_id

    # Step 2: Create article B with related_article_ids pointing to A
    # B is source, A is target in the article_references row
    result_b = tome.create(
      description: "Article B referencing A",
      body: "Body of article B.",
      related_article_ids: [id_a]
    )
    assert result_b.success?, "Create B failed: #{result_b.error_message}"
    id_b = result_b.article_global_id

    # Step 3: related A — referenced_by includes B, references_to is empty
    result_related_a = tome.related(id_a)
    assert result_related_a.success?, "Related A failed: #{result_related_a.error_message}"

    referenced_by_a = result_related_a.data["referenced_by"].map { |r| r["global_id"] }
    references_to_a = result_related_a.data["references_to"].map { |r| r["global_id"] }

    assert_includes referenced_by_a, id_b, "A's referenced_by should include B"
    refute_includes references_to_a, id_b, "A's references_to should not include B"

    # Step 4: related B — references_to includes A, referenced_by is empty
    result_related_b = tome.related(id_b)
    assert result_related_b.success?, "Related B failed: #{result_related_b.error_message}"

    references_to_b = result_related_b.data["references_to"].map { |r| r["global_id"] }
    referenced_by_b = result_related_b.data["referenced_by"].map { |r| r["global_id"] }

    assert_includes references_to_b, id_a, "B's references_to should include A"
    refute_includes referenced_by_b, id_a, "B's referenced_by should not include A"
  end
end
