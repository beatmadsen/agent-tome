require "test_helper"

# AT-7.1: Related via shared keywords
class RelatedSharedKeywordsTest < Minitest::Test
  include TomeDsl

  def test_related_via_shared_keywords
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
      keywords: ["ruby", "gc", "python"]
    )
    assert result_b.success?, "Setup failed: #{result_b.error_message}"
    id_b = result_b.article_global_id

    result = tome.related(id_a)
    assert result.success?, "Related failed: #{result.error_message}"

    shared = result.data["shared_keywords"]
    assert_instance_of Array, shared

    found_b = shared.find { |r| r["global_id"] == id_b }
    refute_nil found_b, "Article B should appear in shared_keywords"
    assert_equal 2, found_b["shared_keyword_count"]

    # Article A must not appear in its own results
    refute shared.any? { |r| r["global_id"] == id_a }, "Article A must not appear in its own shared_keywords"
  end
end
