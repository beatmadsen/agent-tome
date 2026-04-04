require "test_helper"

# AT-9.6: Output format for source-search
class SourceSearchOutputFormatTest < Minitest::Test
  include TomeDsl

  def test_source_search_result_contains_exactly_required_fields
    create_article!(
      description: "Ruby concurrency article",
      body: "Ruby supports threads and fibers.",
      keywords: ["ruby", "concurrency"],
      web_sources: [{ url: "https://ruby-doc.org/output-format-test", title: "Ruby Docs" }]
    )

    result = tome.source_search("https://ruby-doc.org/output-format-test")

    assert_success result
    results = result.results
    assert results.length >= 1, "Expected at least one result"

    r = results.first

    # Exact key set — global_id, description, keywords, created_at (no matching_keyword_count)
    assert_equal %w[global_id description keywords created_at].sort,
                 r.keys.sort,
                 "source-search result should contain exactly global_id, description, keywords, created_at"

    assert_instance_of String, r["global_id"],    "global_id must be a String"
    assert_instance_of String, r["description"],   "description must be a String"
    assert_instance_of Array,  r["keywords"],      "keywords must be an Array"
    r["keywords"].each { |kw| assert_instance_of String, kw }
    assert_instance_of String, r["created_at"],    "created_at must be a String"

    # created_at must be ISO 8601
    assert_match(
      /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})\z/,
      r["created_at"],
      "created_at must be an ISO 8601 datetime string"
    )

    # No internal integer id field
    refute r.key?("id"), "Result must not expose internal integer id"

    # No matching_keyword_count — source-search does not match on keywords
    refute r.key?("matching_keyword_count"), "source-search result must not include matching_keyword_count"
  end
end
