require "test_helper"

# AT-10.2: Success exit code is 0
# Every successful command returns exit code 0.
class ExitCodeSuccessTest < Minitest::Test
  include TomeDsl

  def test_create_success_exits_zero
    result = tome.create(description: "Exit code test article", body: "Content.")
    assert result.success?
    assert_equal 0, result.exit_code, "create success must exit with code 0"
  end

  def test_addend_success_exits_zero
    created = tome.create(description: "Article for addend exit check", body: "Initial body.")
    assert created.success?

    result = tome.addend(created.article_global_id, body: "Addendum content.")
    assert result.success?
    assert_equal 0, result.exit_code, "addend success must exit with code 0"
  end

  def test_search_success_exits_zero
    result = tome.search(["ruby"])
    assert result.success?
    assert_equal 0, result.exit_code, "search success must exit with code 0"
  end

  def test_fetch_success_exits_zero
    created = tome.create(description: "Article for fetch exit check", body: "Body.")
    assert created.success?

    result = tome.fetch(created.article_global_id)
    assert result.success?
    assert_equal 0, result.exit_code, "fetch success must exit with code 0"
  end

  def test_consolidate_success_exits_zero
    created = tome.create(description: "Article for consolidate exit check", body: "Body.")
    assert created.success?

    result = tome.consolidate(created.article_global_id, body: "Consolidated content.")
    assert result.success?
    assert_equal 0, result.exit_code, "consolidate success must exit with code 0"
  end

  def test_related_success_exits_zero
    created = tome.create(description: "Article for related exit check", body: "Body.")
    assert created.success?

    result = tome.related(created.article_global_id)
    assert result.success?
    assert_equal 0, result.exit_code, "related success must exit with code 0"
  end

  def test_keywords_success_exits_zero
    result = tome.keywords("ruby")
    assert result.success?
    assert_equal 0, result.exit_code, "keywords success must exit with code 0"
  end

  def test_source_search_success_exits_zero
    result = tome.source_search("https://example.com/exit-code-check")
    assert result.success?
    assert_equal 0, result.exit_code, "source-search success must exit with code 0"
  end
end
