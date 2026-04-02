require "test_helper"

class KeywordsNoArgumentTest < Minitest::Test
  include TomeDsl

  # AT-8.4: No argument provided
  def test_no_argument_returns_error
    result = tome.keywords(nil)

    refute result.success?
    assert_match(/argument/i, result.error_message)
  end
end
