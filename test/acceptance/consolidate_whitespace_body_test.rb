require "test_helper"

# AT-6.6b: Consolidation rejects whitespace-only body
class ConsolidateWhitespaceBodyTest < Minitest::Test
  include TomeDsl

  def test_consolidation_rejects_whitespace_only_body
    create_result = tome.create(description: "An article", body: "Content.")
    assert create_result.success?, "Setup failed: #{create_result.error_message}"
    article_id = create_result.article_global_id

    result = tome.consolidate(article_id, body: "   ")

    refute result.success?
    assert_match(/body/i, result.error_message)
  end
end
