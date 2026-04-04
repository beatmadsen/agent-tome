require "test_helper"

class KeywordsCaseInsensitiveTest < Minitest::Test
  include TomeDsl

  # AT-8.3: Case-insensitive matching
  def test_keywords_match_case_insensitively
    create_article!(description: "A", body: "x", keywords: ["ruby"])

    result = tome.keywords("RU")

    assert_success result
    assert_includes result.keywords, "ruby"
  end
end
