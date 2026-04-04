require "test_helper"

# AT-2.5: Web source deduplication by normalised URL
class WebSourceDeduplicationTest < Minitest::Test
  include TomeDsl

  def test_tracking_params_stripped_and_existing_source_reused
    # First article with the bare URL
    result_a = create_article!(
      description: "Article A",
      body: "Content A",
      web_sources: [{ url: "https://example.com/page" }]
    )

    original_ws_id = result_a.data["web_source_global_ids"].first
    assert_global_id original_ws_id

    # Second article with tracking params appended — normalises to same URL
    result_b = create_article!(
      description: "Article B",
      body: "Content B",
      web_sources: [{ url: "https://example.com/page?utm_source=twitter&utm_medium=social" }]
    )

    reused_ws_id = result_b.data["web_source_global_ids"].first

    # Same global ID returned — the existing record was reused
    assert_equal original_ws_id, reused_ws_id,
                 "Expected the existing web source to be reused, but a new one was created"

    # Only one web source row in the database
    assert_equal 1, Agent::Tome::WebSource.count,
                 "Expected exactly 1 web source row but found #{Agent::Tome::WebSource.count}"
  end
end
