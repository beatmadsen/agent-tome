require "test_helper"

# AT-2.12: Missing description is rejected
class MissingDescriptionTest < Minitest::Test
  include TomeDsl

  def test_missing_description_is_rejected
    result = tome.create(description: nil, body: "Some content")

    refute result.success?
    assert_match(/description/i, result.error_message)
  end

  def test_no_records_created_when_description_missing
    tome.create(description: nil, body: "Some content")

    assert_equal 0, Agent::Tome::Article.count
  end
end
