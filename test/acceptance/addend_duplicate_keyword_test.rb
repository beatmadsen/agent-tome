require "test_helper"

# AT-3.8: Duplicate keyword on addendum is idempotent
class AddendDuplicateKeywordTest < Minitest::Test
  include TomeDsl

  def test_duplicate_keyword_on_addendum_succeeds_without_duplicate_row
    create_result = tome.create(
      description: "How Ruby GC works",
      body: "Ruby uses a mark-and-sweep garbage collector.",
      keywords: ["ruby"]
    )
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    article_global_id = create_result.article_global_id

    result = tome.addend(article_global_id, keywords: ["ruby"])

    assert result.success?, "Expected success but got error: #{result.error_message}"
    assert_match BASE58_PATTERN, result.entry_global_id

    article = Agent::Tome::Article.find_by(global_id: article_global_id)
    keyword_terms = article.keywords.pluck(:term)
    assert_equal ["ruby"], keyword_terms.sort

    ruby_keyword = Agent::Tome::Keyword.where(term: "ruby")
    assert_equal 1, ruby_keyword.count, "Should be exactly one 'ruby' keyword row"

    article_keyword_count = Agent::Tome::ArticleKeyword.where(
      article_id: article.id,
      keyword_id: ruby_keyword.first.id
    ).count
    assert_equal 1, article_keyword_count, "Should be exactly one article_keywords row for ruby on this article"
  end
end
