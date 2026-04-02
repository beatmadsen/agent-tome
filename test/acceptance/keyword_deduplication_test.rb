require "test_helper"

# AT-2.4: Keyword deduplication across articles
class KeywordDeduplicationTest < Minitest::Test
  include TomeDsl

  def test_keyword_row_is_reused_across_articles
    result1 = tome.create(
      description: "First article about Ruby",
      body: "Ruby is a dynamic language.",
      keywords: ["ruby"]
    )
    assert result1.success?, "Expected first create to succeed: #{result1.error_message}"

    ruby_keyword_count_before = Agent::Tome::Keyword.where(term: "ruby").count
    assert_equal 1, ruby_keyword_count_before, "Expected exactly one 'ruby' keyword row after first create"

    result2 = tome.create(
      description: "Second article mentioning Ruby",
      body: "Ruby also supports metaprogramming.",
      keywords: ["Ruby"]
    )
    assert result2.success?, "Expected second create to succeed: #{result2.error_message}"

    ruby_keyword_count_after = Agent::Tome::Keyword.where(term: "ruby").count
    assert_equal 1, ruby_keyword_count_after, "Expected still exactly one 'ruby' keyword row (no duplicate)"

    article2 = Agent::Tome::Article.find_by!(global_id: result2.article_global_id)
    assert_equal ["ruby"], article2.keywords.pluck(:term),
                 "Expected second article to be linked to the existing 'ruby' keyword"
  end
end
