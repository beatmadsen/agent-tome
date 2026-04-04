require "test_helper"

# AT-7.8: Shared keywords capped at 100
class RelatedSharedKeywordsCapTest < Minitest::Test
  include TomeDsl

  def test_shared_keywords_capped_at_100
    result_a = create_article!(description: "Article A", body: "Body A", keywords: ["ruby"])
    id_a = result_a.article_global_id

    # Create 101 articles all sharing the "ruby" keyword with article A
    101.times do |i|
      create_article!(description: "Article #{i}", body: "Body #{i}", keywords: ["ruby"])
    end

    result = tome.related(id_a)
    assert_success result, "Related failed: #{result.error_message}"

    shared = result.data["shared_keywords"]
    assert shared.length <= 100, "shared_keywords must be capped at 100, got #{shared.length}"
  end
end
