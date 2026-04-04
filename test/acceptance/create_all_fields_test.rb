require "test_helper"

# AT-2.2: Article with all optional fields
class ArticleWithAllOptionalFieldsTest < Minitest::Test
  include TomeDsl

  def test_creates_article_with_keywords_web_and_file_sources
    result = tome.create(
      description: "Concurrency in Ruby",
      body: "Ruby has threads and fibers.",
      keywords: ["concurrency", "Ruby", "threads"],
      web_sources: [
        { url: "https://ruby-doc.org/concurrency", title: "Ruby Concurrency Docs", fetched_at: "2025-06-01T12:00:00Z" }
      ],
      file_sources: [
        { path: "/home/user/notes/ruby-concurrency.md", system_name: "work-laptop" }
      ]
    )

    assert_success result
    assert_global_id result.article_global_id
    assert_global_id result.entry_global_id

    assert_equal 1, result.data["web_source_global_ids"].length
    assert_equal 1, result.data["file_source_global_ids"].length
    assert_global_id result.data["web_source_global_ids"].first
    assert_global_id result.data["file_source_global_ids"].first

    # Keywords are downcased and singularised
    expected_terms = %w[concurrency ruby thread]
    actual_terms = Agent::Tome::Keyword.where(term: expected_terms).pluck(:term).sort
    assert_equal expected_terms.sort, actual_terms,
                 "Expected keywords #{expected_terms} in the keywords table"

    # All three keywords are linked to the article
    article = Agent::Tome::Article.find_by!(global_id: result.article_global_id)
    assert_equal expected_terms.sort, article.keywords.pluck(:term).sort

    # Web source stored with correct attributes
    ws = Agent::Tome::WebSource.find_by!(global_id: result.data["web_source_global_ids"].first)
    assert_equal "https://ruby-doc.org/concurrency", ws.url
    assert_equal "Ruby Concurrency Docs", ws.title
    refute_nil ws.fetched_at

    # File source stored with correct attributes
    fs = Agent::Tome::FileSource.find_by!(global_id: result.data["file_source_global_ids"].first)
    assert_equal "/home/user/notes/ruby-concurrency.md", fs.path
    assert_equal "work-laptop", fs.system_name

    # Entry is linked to both sources
    entry = Agent::Tome::Entry.find_by!(global_id: result.entry_global_id)
    assert_equal [ws.id], entry.entry_web_sources.pluck(:web_source_id)
    assert_equal [fs.id], entry.entry_file_sources.pluck(:file_source_id)
  end
end
