require "test_helper"

# AT-5.3: Fetch article with sources on entries
class FetchArticleWithSourcesTest < Minitest::Test
  include TomeDsl

  def test_entry_sources_are_included_in_fetch_output
    create_result = create_article!(
      description: "Ruby web resources",
      body: "Initial content about Ruby.",
      web_sources: [
        { url: "https://ruby-doc.org/core", title: "Ruby Core Docs", fetched_at: "2025-06-01T12:00:00Z" }
      ],
      file_sources: [
        { path: "/home/user/notes/ruby.md", system_name: "work-laptop" }
      ]
    )
    article_id = create_result.article_global_id

    addend_result = tome.addend(
      article_id,
      body: "More about Ruby concurrency.",
      web_sources: [
        { url: "https://ruby-doc.org/fiber", title: "Fiber Docs" }
      ],
      file_sources: [
        { path: "/home/user/notes/concurrency.md", system_name: "work-laptop" }
      ]
    )
    assert_success addend_result, "Addend failed: #{addend_result.error_message}"

    result = tome.fetch(article_id)
    assert_success result, "Fetch failed: #{result.error_message}"

    entries = result.entries
    assert_equal 2, entries.length

    # First entry: has one web source and one file source
    first_entry = entries[0]
    assert_equal 1, first_entry["web_sources"].length
    ws = first_entry["web_sources"][0]
    assert_global_id ws["global_id"]
    assert_equal "https://ruby-doc.org/core", ws["url"]
    assert_equal "Ruby Core Docs", ws["title"]
    assert_equal "2025-06-01T12:00:00Z", ws["fetched_at"]

    assert_equal 1, first_entry["file_sources"].length
    fs = first_entry["file_sources"][0]
    assert_global_id fs["global_id"]
    assert_equal "/home/user/notes/ruby.md", fs["path"]
    assert_equal "work-laptop", fs["system_name"]

    # Second entry: has one web source and one file source
    second_entry = entries[1]
    assert_equal 1, second_entry["web_sources"].length
    ws2 = second_entry["web_sources"][0]
    assert_global_id ws2["global_id"]
    assert_equal "https://ruby-doc.org/fiber", ws2["url"]
    assert_equal "Fiber Docs", ws2["title"]
    assert_nil ws2["fetched_at"]

    assert_equal 1, second_entry["file_sources"].length
    fs2 = second_entry["file_sources"][0]
    assert_global_id fs2["global_id"]
    assert_equal "/home/user/notes/concurrency.md", fs2["path"]
    assert_equal "work-laptop", fs2["system_name"]
  end
end
