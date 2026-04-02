require "test_helper"

# AT-4.6: Search with no matching results
class SearchNoResultsTest < Minitest::Test
  include TomeDsl

  def test_search_returns_empty_results_when_no_match
    result = tome.search(["nonexistent-keyword"])

    assert result.success?, result.error_message
    assert_equal({ "results" => [] }, result.data)
  end
end
