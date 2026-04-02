require "test_helper"

# AT-7.6: Article appears in multiple relation arrays
class RelatedMultipleArraysTest < Minitest::Test
  include TomeDsl

  def test_article_appears_in_shared_keywords_and_references_to
    # Create article A with keyword "ruby"
    result_a = tome.create(description: "Article A", body: "Body A", keywords: ["ruby"])
    assert result_a.success?, "Setup A failed: #{result_a.error_message}"
    id_a = result_a.article_global_id

    # Create article B with keyword "ruby" AND an ArticleReference from A to B
    result_b = tome.create(
      description: "Article B",
      body: "Body B",
      keywords: ["ruby"],
      related_article_ids: [id_a]
    )
    assert result_b.success?, "Setup B failed: #{result_b.error_message}"
    id_b = result_b.article_global_id

    # related on A: B shares keyword "ruby" with A, and B references A
    # So A should appear in B's shared_keywords AND B's references_to
    result = tome.related(id_b)
    assert result.success?, "Related failed: #{result.error_message}"

    shared_ids = result.data["shared_keywords"].map { |r| r["global_id"] }
    references_to_ids = result.data["references_to"].map { |r| r["global_id"] }

    assert_includes shared_ids, id_a, "A should appear in shared_keywords (both have 'ruby')"
    assert_includes references_to_ids, id_a, "A should appear in references_to (B references A)"
  end
end
