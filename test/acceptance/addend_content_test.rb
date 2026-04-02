require "test_helper"

# AT-3.1: Add content addendum to existing article
class AddendContentTest < Minitest::Test
  include TomeDsl

  def test_adds_entry_to_existing_article
    create_result = tome.create(
      description: "How Ruby GC works",
      body: "Ruby uses a mark-and-sweep garbage collector."
    )
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    article_global_id = create_result.article_global_id

    result = tome.addend(
      article_global_id,
      body: "Additional finding: GC can be tuned via environment variables."
    )

    assert result.success?, "Expected success but got error: #{result.error_message}"
    assert_match BASE58_PATTERN, result.entry_global_id,
                 "entry_global_id should be a 7-character base58 string"

    article = Agent::Tome::Article.find_by(global_id: article_global_id)
    assert_equal 2, article.entries.count, "Article should have two entries"

    new_entry = article.entries.find_by(global_id: result.entry_global_id)
    refute_nil new_entry, "New entry should exist in database"
    assert_equal "Additional finding: GC can be tuned via environment variables.", new_entry.body
  end
end
