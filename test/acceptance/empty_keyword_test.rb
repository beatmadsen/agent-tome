require "test_helper"

# AT-2.15: Empty keyword string is rejected
class EmptyKeywordTest < Minitest::Test
  include TomeDsl

  def test_empty_keyword_is_rejected
    result = tome.create(description: "X", body: "Y", keywords: ["valid", ""])

    refute result.success?
    assert_match(/keyword/i, result.error_message)
  end
end
