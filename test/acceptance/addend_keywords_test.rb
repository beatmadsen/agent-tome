require "test_helper"

# AT-3.2: Add keywords via addendum
class AddendKeywordsTest < Minitest::Test
  include TomeDsl

  def test_adds_keywords_to_article_and_creates_null_body_entry
    create_result = tome.create(
      description: "How Ruby GC works",
      body: "Ruby uses a mark-and-sweep garbage collector.",
      keywords: ["ruby"]
    )
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    article_global_id = create_result.article_global_id

    result = tome.addend(
      article_global_id,
      keywords: ["gc", "performance"]
    )

    assert result.success?, "Expected success but got error: #{result.error_message}"
    assert_match BASE58_PATTERN, result.entry_global_id,
                 "entry_global_id should be a 7-character base58 string"

    article = Agent::Tome::Article.find_by(global_id: article_global_id)

    keyword_terms = article.keywords.pluck(:term)
    assert_includes keyword_terms, "gc"
    assert_includes keyword_terms, "performance"
    assert_includes keyword_terms, "ruby"

    new_entry = article.entries.find_by(global_id: result.entry_global_id)
    refute_nil new_entry, "New entry should exist in database"
    assert_nil new_entry.body, "Entry body should be null for a keywords-only addendum"
  end
end
