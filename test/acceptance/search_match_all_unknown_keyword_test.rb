require "test_helper"

# AT-4.10: Search with --match all and a keyword no article has
class SearchMatchAllUnknownKeywordTest < Minitest::Test
  include TomeDsl

  def test_match_all_finds_nothing_when_one_keyword_is_on_no_article
    create_article!(description: "Article A", body: "body", keywords: ["ruby", "gc"])

    result = tome.search(["ruby", "nosuchword"], match: "all")

    assert_success result
    assert_empty result.data["results"]
  end
end
