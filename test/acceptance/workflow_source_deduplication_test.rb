require "test_helper"

# AT-13.3: Source deduplication across articles
class WorkflowSourceDeduplicationTest < Minitest::Test
  include TomeDsl

  def test_source_deduplication_across_articles
    url = "https://ruby-doc.org/page"

    # Step 1: Create article A with the web source
    result_a = create_article!(
      description: "Article A about Ruby docs",
      body: "First article referencing the Ruby docs page.",
      web_sources: [{ url: url, title: "Ruby Docs" }]
    )
    article_a_id = result_a.article_global_id
    web_source_id_a = result_a.web_source_global_ids.first

    # Step 2: Create article B with the same web source URL — same row reused
    result_b = create_article!(
      description: "Article B also referencing Ruby docs",
      body: "Second article referencing the same Ruby docs page.",
      web_sources: [{ url: url, title: "Ruby Docs Again" }]
    )
    article_b_id = result_b.article_global_id
    web_source_id_b = result_b.web_source_global_ids.first

    # The same web_source row is reused — both entries reference the same global_id
    assert_equal web_source_id_a, web_source_id_b, "Same web source row should be reused"
    refute_equal article_a_id, article_b_id

    # Step 3: source-search returns both articles A and B
    search_result = tome.source_search(url)
    assert_success search_result, "Source search failed: #{search_result.error_message}"

    result_ids = search_result.results.map { |r| r["global_id"] }
    assert_includes result_ids, article_a_id, "Results should include article A"
    assert_includes result_ids, article_b_id, "Results should include article B"
    assert_equal 2, result_ids.length, "Should return exactly 2 articles"
  end
end
