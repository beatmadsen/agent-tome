require "test_helper"

class KeywordsPrefixTest < Minitest::Test
  include TomeDsl

  # AT-8.1: Keywords matching a prefix/substring
  # The implementation uses substring matching, so "guru" is included when searching "ru".
  def test_keywords_matching_substring
    tome.create(description: "A", body: "x", keywords: ["ruby"])
    tome.create(description: "B", body: "x", keywords: ["rust"])
    tome.create(description: "C", body: "x", keywords: ["python"])
    tome.create(description: "D", body: "x", keywords: ["runtime"])
    tome.create(description: "E", body: "x", keywords: ["guru"])

    result = tome.keywords("ru")

    assert result.success?
    keywords = result.keywords
    assert_includes keywords, "ruby"
    assert_includes keywords, "rust"
    assert_includes keywords, "runtime"
    assert_includes keywords, "guru"
    refute_includes keywords, "python"
  end
end
