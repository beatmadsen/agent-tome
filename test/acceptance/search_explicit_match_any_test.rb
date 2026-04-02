require "test_helper"

# AT-4.3: Search with --match any (explicit)
class SearchExplicitMatchAnyTest < Minitest::Test
  include TomeDsl

  def test_explicit_match_any_returns_same_results_as_default
    a = tome.create(description: "Article A", body: "body", keywords: ["ruby", "gc"])
    assert a.success?, a.error_message

    b = tome.create(description: "Article B", body: "body", keywords: ["ruby", "thread"])
    assert b.success?, b.error_message

    c = tome.create(description: "Article C", body: "body", keywords: ["python", "gc"])
    assert c.success?, c.error_message

    result = tome.search(["ruby", "gc"], match: "any")

    assert result.success?, result.error_message
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
