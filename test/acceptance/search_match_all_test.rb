require "test_helper"

# AT-4.2: Search with --match all
class SearchMatchAllTest < Minitest::Test
  include TomeDsl

  def test_match_all_returns_only_articles_having_every_keyword
    a = create_article!(description: "Article A", body: "body", keywords: ["ruby", "gc"])

    b = create_article!(description: "Article B", body: "body", keywords: ["ruby", "thread"])

    c = create_article!(description: "Article C", body: "body", keywords: ["python", "gc"])

    result = tome.search(["ruby", "gc"], match: "all")

    assert_success result
    results = result.data["results"]
    global_ids = results.map { |r| r["global_id"] }

    assert_includes global_ids, a.data["article_global_id"], "Article A (ruby+gc) should match"
    refute_includes global_ids, b.data["article_global_id"], "Article B (ruby only) should not match"
    refute_includes global_ids, c.data["article_global_id"], "Article C (gc only) should not match"
  end
end
