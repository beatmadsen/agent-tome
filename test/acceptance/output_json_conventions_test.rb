require "test_helper"

# AT-10.1: All commands output JSON to stdout
# The convention: every command, on success or failure, returns structured data
# (not plain text, stack traces, or unstructured output).
class OutputJsonConventionsTest < Minitest::Test
  include TomeDsl

  def test_create_success_returns_hash_data
    result = tome.create(description: "JSON output check", body: "Content for JSON test.")
    assert_success result, "Expected create to succeed: #{result.error_message}"
    assert_instance_of Hash, result.data, "create success must return Hash data"
  end

  def test_fetch_success_returns_hash_data
    created = create_article!(description: "Article to fetch", body: "Body content.")

    result = tome.fetch(created.article_global_id)
    assert_success result, "Expected fetch to succeed: #{result.error_message}"
    assert_instance_of Hash, result.data, "fetch success must return Hash data"
  end

  def test_search_success_returns_hash_data
    result = tome.search(["ruby"])
    assert_success result, "Expected search to succeed: #{result.error_message}"
    assert_instance_of Hash, result.data, "search success must return Hash data"
  end

  def test_keywords_success_returns_hash_data
    result = tome.keywords("rub")
    assert_success result, "Expected keywords to succeed: #{result.error_message}"
    assert_instance_of Hash, result.data, "keywords success must return Hash data"
  end

  def test_source_search_success_returns_hash_data
    result = tome.source_search("https://example.com/json-check")
    assert_success result, "Expected source-search to succeed: #{result.error_message}"
    assert_instance_of Hash, result.data, "source-search success must return Hash data"
  end

  def test_fetch_error_returns_structured_error_message
    result = tome.fetch("INVALID")
    assert result.failure?, "Expected fetch of non-existent article to fail"
    refute_nil result.error_message, "Error result must carry an error message"
    assert_kind_of String, result.error_message, "Error message must be a String"
    refute result.error_message.empty?, "Error message must not be empty"
  end

  def test_create_validation_error_returns_structured_error_message
    result = tome.create(description: "X", body: nil)
    assert result.failure?, "Expected create with no body to fail"
    refute_nil result.error_message
    assert_kind_of String, result.error_message
    refute result.error_message.empty?
  end

  def test_related_success_returns_hash_data
    created = create_article!(description: "Article for related check", body: "Body.")

    result = tome.related(created.article_global_id)
    assert_success result, "Expected related to succeed: #{result.error_message}"
    assert_instance_of Hash, result.data, "related success must return Hash data"
  end

  def test_addend_success_returns_hash_data
    created = create_article!(description: "Article for addend JSON check", body: "Initial body.")

    result = tome.addend(created.article_global_id, body: "Addendum content.")
    assert_success result, "Expected addend to succeed: #{result.error_message}"
    assert_instance_of Hash, result.data, "addend success must return Hash data"
  end

  def test_consolidate_success_returns_hash_data
    created = create_article!(description: "Article for consolidate JSON check", body: "Initial body.")

    result = tome.consolidate(created.article_global_id, body: "Consolidated content.")
    assert_success result, "Expected consolidate to succeed: #{result.error_message}"
    assert_instance_of Hash, result.data, "consolidate success must return Hash data"
  end
end
