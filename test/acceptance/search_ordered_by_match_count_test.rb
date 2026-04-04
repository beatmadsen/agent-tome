require "test_helper"

# AT-4.4: Search results ordered by matching keyword count descending
class SearchOrderedByMatchCountTest < Minitest::Test
  include TomeDsl

  def test_results_ordered_by_matching_keyword_count_descending
    a = create_article!(description: "Article A", body: "body", keywords: ["ruby", "gc", "performance"])

    b = create_article!(description: "Article B", body: "body", keywords: ["ruby"])

    result = tome.search(["ruby", "gc", "performance"])

    assert_success result
    results = result.data["results"]

    global_ids = results.map { |r| r["global_id"] }
    assert_includes global_ids, a.data["article_global_id"], "Article A should be in results"
    assert_includes global_ids, b.data["article_global_id"], "Article B should be in results"

    a_pos = global_ids.index(a.data["article_global_id"])
    b_pos = global_ids.index(b.data["article_global_id"])
    assert a_pos < b_pos, "Article A (3 matches) should appear before Article B (1 match)"

    a_result = results.find { |r| r["global_id"] == a.data["article_global_id"] }
    b_result = results.find { |r| r["global_id"] == b.data["article_global_id"] }
    assert_equal 3, a_result["matching_keyword_count"]
    assert_equal 1, b_result["matching_keyword_count"]
  end
end
