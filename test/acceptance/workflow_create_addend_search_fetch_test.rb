require "test_helper"

# AT-13.1: Create, addend, search, fetch lifecycle
class WorkflowCreateAddendSearchFetchTest < Minitest::Test
  include TomeDsl

  def test_full_lifecycle
    # Step 1: Create article
    create_result = tome.create(
      description: "Ruby GC internals",
      body: "Mark and sweep",
      keywords: ["ruby", "gc"]
    )
    assert create_result.success?, "Create failed: #{create_result.error_message}"
    article_id = create_result.article_global_id
    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\z/, article_id)

    # Step 2: Addend the article
    addend_result = tome.addend(
      article_id,
      body: "Generational GC added in 2.1",
      keywords: ["performance"]
    )
    assert addend_result.success?, "Addend failed: #{addend_result.error_message}"

    # Step 3: Search for ruby gc — should return article X with matching_keyword_count: 2
    search_result = tome.search(["ruby", "gc"])
    assert search_result.success?, "Search failed: #{search_result.error_message}"

    results = search_result.results
    matching = results.find { |r| r["global_id"] == article_id }
    refute_nil matching, "Article X not found in search results"
    assert_equal 2, matching["matching_keyword_count"]

    # Step 4: Fetch article X — should have 2 entries and all 3 keywords
    fetch_result = tome.fetch(article_id)
    assert fetch_result.success?, "Fetch failed: #{fetch_result.error_message}"

    data = fetch_result.data
    assert_equal article_id, data["global_id"]

    assert_equal 2, data["entries"].length, "Expected 2 entries (original + addendum)"
    assert_equal "Mark and sweep", data["entries"][0]["body"]
    assert_equal "Generational GC added in 2.1", data["entries"][1]["body"]

    keywords = data["keywords"].sort
    assert_equal ["gc", "performance", "ruby"], keywords
  end
end
