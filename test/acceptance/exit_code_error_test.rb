require "test_helper"

# AT-10.3: Error exit code is non-zero
# Every failing command must return a non-zero exit code.
class ExitCodeErrorTest < Minitest::Test
  include TomeDsl

  def test_create_validation_error_exits_nonzero
    result = tome.create(description: "X", body: nil)
    assert result.failure?
    refute_equal 0, result.exit_code, "create validation error must exit with non-zero code"
  end

  def test_fetch_not_found_exits_nonzero
    result = tome.fetch("INVALID")
    assert result.failure?
    refute_equal 0, result.exit_code, "fetch not found must exit with non-zero code"
  end

  def test_addend_not_found_exits_nonzero
    result = tome.addend("INVALID", body: "Some content.")
    assert result.failure?
    refute_equal 0, result.exit_code, "addend not found must exit with non-zero code"
  end

  def test_search_no_keywords_exits_nonzero
    result = tome.search([])
    assert result.failure?
    refute_equal 0, result.exit_code, "search with no keywords must exit with non-zero code"
  end

  def test_consolidate_not_found_exits_nonzero
    result = tome.consolidate("INVALID", body: "Content.")
    assert result.failure?
    refute_equal 0, result.exit_code, "consolidate not found must exit with non-zero code"
  end

  def test_related_not_found_exits_nonzero
    result = tome.related("INVALID")
    assert result.failure?
    refute_equal 0, result.exit_code, "related not found must exit with non-zero code"
  end

  def test_keywords_no_argument_exits_nonzero
    result = tome.keywords(nil)
    assert result.failure?
    refute_equal 0, result.exit_code, "keywords with no argument must exit with non-zero code"
  end
end
