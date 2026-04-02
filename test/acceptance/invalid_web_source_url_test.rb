require "test_helper"

# AT-2.16: Invalid web source URL is rejected
class InvalidWebSourceUrlTest < Minitest::Test
  include TomeDsl

  def test_invalid_url_is_rejected
    result = tome.create(
      description: "Some article",
      body: "Some body",
      web_sources: [{ "url" => "not-a-url" }]
    )

    refute result.success?
    assert_match(/url/i, result.error_message)
  end
end
