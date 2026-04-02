require "test_helper"

# AT-7.2: Related via shared keywords ordering
class RelatedSharedKeywordsOrderingTest < Minitest::Test
  include TomeDsl

  def test_related_shared_keywords_ordered_by_shared_count_descending
    result_a = tome.create(
      description: "Article A",
      body: "Body A",
      keywords: ["ruby", "gc", "performance"]
    )
    assert result_a.success?, "Setup failed: #{result_a.error_message}"
    id_a = result_a.article_global_id

    result_b = tome.create(
      description: "Article B",
      body: "Body B",
      keywords: ["ruby", "gc"]
    )
    assert result_b.success?, "Setup failed: #{result_b.error_message}"
    id_b = result_b.article_global_id

    result_c = tome.create(
      description: "Article C",
      body: "Body C",
      keywords: ["ruby"]
    )
    assert result_c.success?, "Setup failed: #{result_c.error_message}"
    id_c = result_c.article_global_id

    result = tome.related(id_a)
    assert result.success?, "Related failed: #{result.error_message}"

    shared = result.data["shared_keywords"]
    assert_instance_of Array, shared

    ids_in_order = shared.map { |r| r["global_id"] }
    idx_b = ids_in_order.index(id_b)
    idx_c = ids_in_order.index(id_c)

    refute_nil idx_b, "Article B should appear in shared_keywords"
    refute_nil idx_c, "Article C should appear in shared_keywords"

    assert idx_b < idx_c, "Article B (2 shared keywords) should appear before Article C (1 shared keyword)"
  end
end
