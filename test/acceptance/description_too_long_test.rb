require "test_helper"

# AT-2.11: Description exceeding 350 characters is rejected
class DescriptionTooLongTest < Minitest::Test
  include TomeDsl

  def test_description_exceeding_350_chars_is_rejected
    long_description = "x" * 351

    result = tome.create(
      description: long_description,
      body: "Some content"
    )

    refute result.success?
    assert_match(/350/i, result.error_message)
  end

  def test_no_records_created_when_description_too_long
    long_description = "x" * 351

    tome.create(
      description: long_description,
      body: "Some content"
    )

    assert_equal 0, Agent::Tome::Article.count, "No article should be created"
  end
end
