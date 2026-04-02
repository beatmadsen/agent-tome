require "test_helper"

# AT-5.5: Fetch non-existent article
class FetchNonexistentArticleTest < Minitest::Test
  include TomeDsl

  def test_returns_error_for_unknown_global_id
    result = tome.fetch("INVALID")

    refute result.success?
    assert result.failure?
    assert_match(/not found/i, result.error_message)
  end
end
