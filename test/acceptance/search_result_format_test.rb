require "test_helper"

# AT-4.8: Search result format
class SearchResultFormatTest < Minitest::Test
  include TomeDsl

  def test_search_result_contains_exactly_required_fields_with_correct_types
    tome.create(description: "Ruby GC internals", body: "body", keywords: ["ruby", "gc"])

    result = tome.search(["ruby"])

    assert_success result
    results = result.data["results"]
    assert results.length >= 1, "Expected at least one result"

    r = results.first

    # Exact key set — no more, no less
    assert_equal %w[global_id description keywords matching_keyword_count created_at].sort,
                 r.keys.sort,
                 "Result should contain exactly the specified keys"

    # Type assertions
    assert_instance_of String, r["global_id"],              "global_id must be a String"
    assert_instance_of String, r["description"],             "description must be a String"
    assert_instance_of Array,  r["keywords"],                "keywords must be an Array"
    r["keywords"].each do |kw|
      assert_instance_of String, kw, "each keyword must be a String"
    end
    assert_instance_of Integer, r["matching_keyword_count"], "matching_keyword_count must be an Integer"
    assert_instance_of String,  r["created_at"],             "created_at must be a String"

    # created_at must be ISO 8601
    assert_match(
      /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})\z/,
      r["created_at"],
      "created_at must be an ISO 8601 datetime string"
    )

    # No internal integer id field
    refute r.key?("id"), "Result must not expose internal integer id"
  end
end
