require "test_helper"

# AT-5.1: Fetch a simple article
class FetchSimpleArticleTest < Minitest::Test
  include TomeDsl

  def test_fetches_article_with_expected_fields
    create_result = tome.create(
      description: "How Ruby GC works",
      body: "Ruby uses a mark-and-sweep garbage collector.",
      keywords: ["ruby"]
    )
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    article_global_id = create_result.article_global_id
    entry_global_id = create_result.entry_global_id

    result = tome.fetch(article_global_id)

    assert result.success?, "Expected success but got error: #{result.error_message}"
    assert_equal article_global_id, result.global_id
    assert_equal "How Ruby GC works", result.description
    assert_match(/\A\d{4}-\d{2}-\d{2}T/, result.created_at)
    assert_equal ["ruby"], result.keywords
    refute result.data.key?("consolidated_from"), "consolidated_from should not be present"

    entries = result.entries
    assert_equal 1, entries.length
    entry = entries.first
    assert_equal entry_global_id, entry["global_id"]
    assert_equal "Ruby uses a mark-and-sweep garbage collector.", entry["body"]
    assert_match(/\A\d{4}-\d{2}-\d{2}T/, entry["created_at"])
    assert_equal [], entry["web_sources"]
    assert_equal [], entry["file_sources"]
  end
end
