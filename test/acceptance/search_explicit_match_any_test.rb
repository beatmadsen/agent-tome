require "test_helper"

# AT-4.3: Search with --match any (explicit)
class SearchExplicitMatchAnyTest < Minitest::Test
  include TomeDsl

  def test_explicit_match_any_returns_same_results_as_default
    a = create_article!(description: "Article A", body: "body", keywords: ["ruby", "gc"])

    b = create_article!(description: "Article B", body: "body", keywords: ["ruby", "thread"])

    c = create_article!(description: "Article C", body: "body", keywords: ["python", "gc"])

    result = tome.search(["ruby", "gc"], match: "any")

    assert_success result
    results = result.data["results"]
    global_ids = results.map { |r| r["global_id"] }

    assert_includes global_ids, a.data["article_global_id"], "Article A should be in results"
    assert_includes global_ids, b.data["article_global_id"], "Article B should be in results"
    assert_includes global_ids, c.data["article_global_id"], "Article C should be in results"

    # Article A matches 2 keywords — should be first
    assert_equal a.data["article_global_id"], results.first["global_id"],
                 "Article A (2 matches) should appear first"
  end
end
