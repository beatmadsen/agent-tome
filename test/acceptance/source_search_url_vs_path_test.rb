require "test_helper"

class SourceSearchUrlVsPathTest < Minitest::Test
  include TomeDsl

  # AT-9.7: URL vs file path disambiguation
  # Arguments beginning with http:// or https:// are treated as URLs (matched against web_sources).
  # All other arguments are treated as file paths (matched against file_sources).

  def test_https_argument_matched_against_web_sources_not_file_sources
    # Create an article with a web source
    web_article = tome.create(
      description: "Article with web source",
      body: "Web content",
      web_sources: [{ url: "https://example.com/page", title: "Example" }]
    )
    assert web_article.success?

    # Create an article with a file source whose path looks similar
    file_article = tome.create(
      description: "Article with file source",
      body: "File content",
      file_sources: [{ path: "https://example.com/page", system_name: "work-laptop" }]
    )
    assert file_article.success?

    result = tome.source_search("https://example.com/page")

    assert result.success?
    global_ids = result.results.map { |r| r["global_id"] }
    assert_includes global_ids, web_article.article_global_id,
      "URL argument should match web source article"
    refute_includes global_ids, file_article.article_global_id,
      "URL argument should NOT match file source article"
  end

  def test_path_argument_matched_against_file_sources_not_web_sources
    # Create an article with a file source
    file_article = tome.create(
      description: "Article with file source",
      body: "File content",
      file_sources: [{ path: "/home/user/doc.pdf", system_name: "work-laptop" }]
    )
    assert file_article.success?

    # Create an article with a web source whose URL contains the same path segment
    web_article = tome.create(
      description: "Article with web source matching path",
      body: "Web content",
      web_sources: [{ url: "https://example.com/home/user/doc.pdf", title: "Web Doc" }]
    )
    assert web_article.success?

    result = tome.source_search("/home/user/doc.pdf")

    assert result.success?
    global_ids = result.results.map { |r| r["global_id"] }
    assert_includes global_ids, file_article.article_global_id,
      "Path argument should match file source article"
    refute_includes global_ids, web_article.article_global_id,
      "Path argument should NOT match web source article"
  end

  def test_http_argument_is_also_treated_as_url
    http_article = tome.create(
      description: "Article with http web source",
      body: "HTTP content",
      web_sources: [{ url: "http://example.com/page", title: "HTTP Example" }]
    )
    assert http_article.success?

    result = tome.source_search("http://example.com/page")

    assert result.success?
    global_ids = result.results.map { |r| r["global_id"] }
    assert_includes global_ids, http_article.article_global_id
  end
end
