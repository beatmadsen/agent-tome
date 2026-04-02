require "test_helper"

# AT-6.9: Consolidation of non-existent article
class ConsolidateNotFoundTest < Minitest::Test
  include TomeDsl

  def test_consolidate_non_existent_article
    result = tome.consolidate("INVALID7", body: "Some merged content.")

    refute result.success?
    assert_match(/not found/i, result.error_message)
  end
end
