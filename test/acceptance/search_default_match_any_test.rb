require "test_helper"

# AT-4.1: Search with default match mode (any)
class SearchDefaultMatchAnyTest < Minitest::Test
  include TomeDsl

  def test_search_default_returns_all_articles_matching_any_keyword
    a = create_article!(description: "Article A", body: "body", keywords: ["ruby", "gc"])

    b = create_article!(description: "Article B", body: "body", keywords: ["ruby", "thread"])

    c = create_article!(description: "Article C", body: "body", keywords: ["python", "gc"])

    result = tome.search(["ruby", "gc"])

    assert_success result
    results = result.data["results"]
    assert_instance_of Array, results

    global_ids = results.map { |r| r["global_id"] }
    assert_includes global_ids, a.data["article_global_id"], "Article A should be in results"
    assert_includes global_ids, b.data["article_global_id"], "Article B should be in results"
    assert_includes global_ids, c.data["article_global_id"], "Article C should be in results"

    # Article A matches 2 keywords — should be first
    first_result = results.first
    assert_equal a.data["article_global_id"], first_result["global_id"],
                 "Article A (2 matches) should appear first"

    # Each result has the required fields
    results.each do |r|
      assert r.key?("global_id"),              "missing global_id"
      assert r.key?("description"),            "missing description"
      assert r.key?("keywords"),               "missing keywords"
      assert r.key?("matching_keyword_count"), "missing matching_keyword_count"
      assert r.key?("created_at"),             "missing created_at"
    end

    a_result = results.find { |r| r["global_id"] == a.data["article_global_id"] }
    assert_equal 2, a_result["matching_keyword_count"]

    b_result = results.find { |r| r["global_id"] == b.data["article_global_id"] }
    assert_equal 1, b_result["matching_keyword_count"]

    c_result = results.find { |r| r["global_id"] == c.data["article_global_id"] }
    assert_equal 1, c_result["matching_keyword_count"]
  end
end
