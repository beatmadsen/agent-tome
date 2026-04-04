require "test_helper"

class SourceSearchNoMatchTest < Minitest::Test
  include TomeDsl

  # AT-9.5: No matching source
  def test_no_matching_source_returns_empty_results
    result = tome.source_search("https://nonexistent.example.com")

    assert_success result
    assert_equal [], result.results
  end
end
