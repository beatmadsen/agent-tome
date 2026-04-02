require "test_helper"

# AT-2.6: Web source URL normalisation preserves non-tracking query params
class WebSourceUrlNormalisationTest < Minitest::Test
  include TomeDsl

  def test_tracking_params_stripped_non_tracking_params_preserved
    result = tome.create(
      description: "Article with mixed query params",
      body: "Some content",
      web_sources: [{ url: "https://example.com/search?q=ruby&page=2&utm_campaign=test" }]
    )
    assert result.success?, result.error_message

    stored_url = Agent::Tome::WebSource.first.url
    assert_equal "https://example.com/search?q=ruby&page=2", stored_url,
                 "Expected utm_campaign to be stripped but q and page to be preserved"
  end
end
