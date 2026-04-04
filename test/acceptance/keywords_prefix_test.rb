require "test_helper"

class KeywordsPrefixTest < Minitest::Test
  include TomeDsl

  # AT-8.1: Keywords matching a prefix/substring
  # The implementation uses substring matching, so "guru" is included when searching "ru".
  def test_keywords_matching_substring
    create_article!(description: "A", body: "x", keywords: ["ruby"])
    create_article!(description: "B", body: "x", keywords: ["rust"])
    create_article!(description: "C", body: "x", keywords: ["python"])
    create_article!(description: "D", body: "x", keywords: ["runtime"])
    create_article!(description: "E", body: "x", keywords: ["guru"])

    result = tome.keywords("ru")

    assert_success result
    keywords = result.keywords
    assert_includes keywords, "ruby"
    assert_includes keywords, "rust"
    assert_includes keywords, "runtime"
    assert_includes keywords, "guru"
    refute_includes keywords, "python"
  end
end
