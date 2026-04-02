require "test_helper"

# AT-2.14: Blank/whitespace-only body is rejected
class BlankBodyTest < Minitest::Test
  include TomeDsl

  def test_whitespace_only_body_is_rejected
    result = tome.create(description: "Something", body: "   ")

    refute result.success?
    assert_match(/body/i, result.error_message)
  end

  def test_no_records_created_when_body_is_blank
    tome.create(description: "Something", body: "   ")

    assert_equal 0, Agent::Tome::Article.count
  end
end
