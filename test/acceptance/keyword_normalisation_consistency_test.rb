require "test_helper"

# AT-2.3b: Keywords are normalised identically across create, addend, and search
class KeywordNormalisationConsistencyTest < Minitest::Test
  include TomeDsl

  def test_keyword_normalised_via_create_is_findable_via_search
    result = create_article!(
      description: "Created with mixed-case plural",
      body: "body",
      keywords: ["Multi-Word-APIs"]
    )

    search = tome.search(["multi-word-apis"])
    assert_success search
    ids = search.data["results"].map { |r| r["global_id"] }
    assert_includes ids, result.data["article_global_id"],
      "Article created with 'Multi-Word-APIs' should match search for 'multi-word-apis'"
  end

  def test_keyword_normalised_via_addend_is_findable_via_search
    create_result = tome.create(
      description: "Base article for addend test",
      body: "body"
    )
    assert create_result.success?, create_result.error_message

    addend_result = tome.addend(
      create_result.data["article_global_id"],
      keywords: ["Running-Processes"]
    )
    assert addend_result.success?, addend_result.error_message

    search = tome.search(["running-processes"])
    assert search.success?, search.error_message
    ids = search.data["results"].map { |r| r["global_id"] }
    assert_includes ids, create_result.data["article_global_id"],
      "Article with addended keyword 'Running-Processes' should match search for 'running-processes'"
  end

  def test_same_keyword_via_create_and_addend_deduplicates_to_one_record
    a = tome.create(
      description: "Article A",
      body: "body",
      keywords: ["Web-Sources"]
    )
    assert a.success?, a.error_message

    b = tome.create(description: "Article B", body: "body")
    assert b.success?, b.error_message

    tome.addend(b.data["article_global_id"], keywords: ["web-sources"])

    search = tome.search(["WEB-SOURCES"])
    assert search.success?, search.error_message
    ids = search.data["results"].map { |r| r["global_id"] }
    assert_includes ids, a.data["article_global_id"]
    assert_includes ids, b.data["article_global_id"],
      "Both articles should be found: normalization must be identical across create, addend, and search"
  end
end
