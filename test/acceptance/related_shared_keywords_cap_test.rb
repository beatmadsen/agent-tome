require "test_helper"

# AT-7.8: Shared keywords capped at 100
class RelatedSharedKeywordsCapTest < Minitest::Test
  include TomeDsl

  def test_shared_keywords_capped_at_100
    result_a = tome.create(description: "Article A", body: "Body A", keywords: ["ruby"])
    assert result_a.success?, "Setup failed: #{result_a.error_message}"
    id_a = result_a.article_global_id

    # Create 101 articles all sharing the "ruby" keyword with article A
    101.times do |i|
      r = tome.create(description: "Article #{i}", body: "Body #{i}", keywords: ["ruby"])
      assert r.success?, "Failed to create article #{i}: #{r.error_message}"
    end

    result = tome.related(id_a)
    assert result.success?, "Related failed: #{result.error_message}"

    shared = result.data["shared_keywords"]
    assert shared.length <= 100, "shared_keywords must be capped at 100, got #{shared.length}"
  end
end
