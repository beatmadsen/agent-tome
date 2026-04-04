require "test_helper"

# AT-3.3: Metadata-only addendum (no body, just sources)
class AddendMetadataOnlyTest < Minitest::Test
  include TomeDsl

  def test_addendum_with_only_web_source_creates_null_body_entry
    create_result = create_article!(
      description: "Ruby concurrency overview",
      body: "Ruby has threads and fibers."
    )
    article_global_id = create_result.article_global_id

    result = tome.addend(
      article_global_id,
      web_sources: [{ url: "https://example.com/new-source", title: "New" }]
    )

    assert_success result
    assert_global_id result.entry_global_id,
                     "entry_global_id should be a 7-character base58 string"

    article = Agent::Tome::Article.find_by(global_id: article_global_id)
    new_entry = article.entries.find_by(global_id: result.entry_global_id)
    refute_nil new_entry, "New entry should exist in database"
    assert_nil new_entry.body, "Entry body should be null for a sources-only addendum"

    assert_equal 1, new_entry.web_sources.count
    assert_equal "https://example.com/new-source", new_entry.web_sources.first.url
  end
end
