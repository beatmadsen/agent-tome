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

    assert_success result
    assert_global_id result.article_global_id
  end
end
