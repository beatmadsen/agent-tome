require "test_helper"

class SourceSearchUrlNormalisationTest < Minitest::Test
  include TomeDsl

  # AT-9.2: URL is normalised before matching
  def test_tracking_params_stripped_before_matching
    create_article!(
      description: "Example article",
      body: "Some content.",
      web_sources: [{ url: "https://example.com/page" }]
    )

    result = tome.source_search("https://example.com/page?utm_source=twitter")

    assert_success result
    assert_equal 1, result.results.length
  end
end
