require "test_helper"

# AT-2.13: Missing body is rejected
class MissingBodyTest < Minitest::Test
  include TomeDsl

  def test_missing_body_is_rejected
    result = tome.create(description: "Something")

    refute result.success?
    assert_match(/body/i, result.error_message)
  end

  def test_no_records_created_when_body_missing
    tome.create(description: "Something")

    assert_equal 0, Agent::Tome::Article.count
  end
end
