require "test_helper"

class KeywordsWildcardLiteralTest < Minitest::Test
  include TomeDsl

  # AT-8.5: SQL wildcard characters in the argument match literally
  def test_underscore_matches_only_keywords_containing_an_underscore
    create_article!(keywords: ["snake_case", "plain"])

    result = tome.keywords("_")

    assert_success result
    assert_equal ["snake_case"], result.keywords
  end

  def test_percent_sign_matches_only_keywords_containing_a_percent_sign
    create_article!(keywords: ["100%", "plain"])

    result = tome.keywords("%")

    assert_success result
    assert_equal ["100%"], result.keywords
  end
end
