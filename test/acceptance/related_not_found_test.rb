require "test_helper"

# AT-7.9: Related for non-existent article
class RelatedNotFoundTest < Minitest::Test
  include TomeDsl

  def test_related_for_nonexistent_article_returns_error
    result = tome.related("INVALID")

    refute result.success?
    assert_match(/not found/i, result.error_message)
  end
end
