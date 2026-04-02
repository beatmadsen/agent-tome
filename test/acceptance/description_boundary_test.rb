require "test_helper"

# AT-2.19: Description at exactly 350 characters is accepted
class DescriptionBoundaryTest < Minitest::Test
  include TomeDsl

  def test_description_at_exactly_350_chars_is_accepted
    description = "x" * 350

    result = tome.create(
      description: description,
      body: "Some content"
    )

    assert result.success?, "Expected success but got: #{result.error_message}"
    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\z/, result.article_global_id)
  end
end
