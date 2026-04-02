require "test_helper"

# AT-4.5: Search keywords are normalised before matching
class SearchKeywordNormalisationTest < Minitest::Test
  include TomeDsl

  def test_search_keywords_are_singularised_and_downcased_before_matching
    a = tome.create(description: "Threads article", body: "body", keywords: ["thread"])
    assert a.success?, a.error_message

    b = tome.create(description: "Processes article", body: "body", keywords: ["process"])
    assert b.success?, b.error_message

    result = tome.search(["Threads", "Processes"])

    assert result.success?, result.error_message
    global_ids = result.data["results"].map { |r| r["global_id"] }

    assert_includes global_ids, a.data["article_global_id"],
                    "Article with keyword 'thread' should match search for 'Threads'"
    assert_includes global_ids, b.data["article_global_id"],
                    "Article with keyword 'process' should match search for 'Processes'"
  end
end
