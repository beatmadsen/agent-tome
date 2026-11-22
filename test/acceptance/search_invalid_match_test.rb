require "test_helper"

class SearchInvalidMatchTest < Minitest::Test
  include TomeDsl

  # AT-4.11: Search with a --match value other than any or all
  def test_unrecognised_match_value_is_rejected
    create_article!(keywords: ["ruby"])

    result = tome.search(["ruby"], match: "al")

    refute result.success?
    assert_match(/--match/, result.error_message)
  end

  # AT-4.12: Search with --match and no value after it
  def test_match_flag_without_a_value_is_rejected
    create_article!(keywords: ["ruby"])

    result = tome.search(["ruby"], match: nil)

    refute result.success?
    assert_match(/--match/, result.error_message)
  end
end
