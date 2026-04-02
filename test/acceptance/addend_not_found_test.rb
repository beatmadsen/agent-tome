require "test_helper"

# AT-3.7: Addendum to non-existent article is rejected
class AddendNotFoundTest < Minitest::Test
  include TomeDsl

  def test_addend_to_nonexistent_article_is_rejected
    result = tome.addend("INVALID", body: "Some content")

    refute result.success?
    assert_match(/not found/i, result.error_message)
  end

  def test_exit_code_is_nonzero
    result = tome.addend("INVALID", body: "Some content")

    assert result.exit_code != 0
  end
end
