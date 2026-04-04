require "test_helper"

# AT-6.2b: Consolidation copies sources to consolidated entry
class ConsolateCopiesSourcesTest < Minitest::Test
  include TomeDsl

  def test_consolidation_copies_all_sources_from_old_entries_to_new_entry
    # Create article with a web source and file source on the first entry
    create_result = create_article!(
      description: "Article with sources across entries",
      body: "First entry content.",
      web_sources: [{ url: "https://example.com/a", title: "Source A" }],
      file_sources: [{ path: "/docs/a.pdf", system_name: "laptop" }]
    )
    article_id = create_result.article_global_id

    # Add a second entry with another web source
    addend_result = tome.addend(article_id,
      body: "Second entry content.",
      web_sources: [{ url: "https://example.com/b", title: "Source B" }]
    )
    assert_success addend_result, "Addend failed: #{addend_result.error_message}"

    # Consolidate
    result = tome.consolidate(article_id, body: "Merged content from both entries.")
    assert_success result, "Consolidate failed: #{result.error_message}"

    # Fetch the consolidated article and check sources on the single entry
    fetch_result = tome.fetch(result.new_article_global_id)
    assert_success fetch_result

    entries = fetch_result.data["entries"]
    assert_equal 1, entries.length, "Consolidated article should have exactly one entry"

    entry = entries.first
    web_urls = entry["web_sources"].map { |ws| ws["url"] }.sort
    file_paths = entry["file_sources"].map { |fs| fs["path"] }

    assert_equal ["https://example.com/a", "https://example.com/b"], web_urls
    assert_equal ["/docs/a.pdf"], file_paths
  end
end
