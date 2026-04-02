require "test_helper"

# AT-4.9: Search with no keywords
class SearchNoKeywordsTest < Minitest::Test
  include TomeDsl

  def test_search_with_no_keywords_is_rejected
    result = tome.search([])

    refute result.success?
    assert_match(/keyword/i, result.error_message)
  end
end
