require "test_helper"

class SourceSearchByUrlTest < Minitest::Test
  include TomeDsl

  # AT-9.1: Search by URL
  def test_search_by_url_returns_linked_articles
    web_source = { url: "https://ruby-doc.org/concurrency", title: "Ruby Concurrency Docs" }
    create_result = create_article!(
      description: "Ruby concurrency article",
      body: "Ruby supports threads and fibers.",
      web_sources: [web_source]
    )

    result = tome.source_search("https://ruby-doc.org/concurrency")

    assert_success result
    results = result.results
    assert_equal 1, results.length
    assert_equal create_result.article_global_id, results.first["global_id"]
  end
end
