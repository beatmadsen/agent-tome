require "test_helper"

class KeywordsNoMatchTest < Minitest::Test
  include TomeDsl

  # AT-8.2: No matching keywords
  def test_no_matching_keywords
    result = tome.keywords("zzz")

    assert result.success?
    assert_empty result.keywords
  end
end
