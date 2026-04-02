require "test_helper"

# AT-10.4: Errors are reported as structured JSON
# When any command fails, the output is a JSON object with a clear error message,
# not a stack trace or unstructured text.
class StructuredErrorsTest < Minitest::Test
  include TomeDsl

  def test_validation_error_carries_non_empty_message
    result = tome.create(description: "X", body: nil)
    assert result.failure?
    refute_nil result.error_message, "Validation failure must carry an error message"
    assert_kind_of String, result.error_message
    refute result.error_message.empty?, "Error message must not be blank"
  end

  def test_not_found_error_carries_non_empty_message
    result = tome.fetch("INVALID")
    assert result.failure?
    refute_nil result.error_message, "Not-found failure must carry an error message"
    refute result.error_message.empty?
  end

  def test_error_message_is_not_a_ruby_backtrace
    # A Ruby backtrace line looks like: path/to/file.rb:42:in `method_name'
    result = tome.fetch("INVALID")
    assert result.failure?
    refute_match(/\.rb:\d+:in/, result.error_message, "Error message must not be a stack trace")
  end

  def test_description_too_long_error_is_structured
    result = tome.create(description: "X" * 351, body: "Content")
    assert result.failure?
    refute_nil result.error_message
    refute_match(/\.rb:\d+:in/, result.error_message)
  end

  def test_addend_not_found_error_is_structured
    result = tome.addend("INVALID", body: "Content")
    assert result.failure?
    refute_nil result.error_message
    refute_match(/\.rb:\d+:in/, result.error_message)
  end

  def test_consolidate_not_found_error_is_structured
    result = tome.consolidate("INVALID", body: "Content")
    assert result.failure?
    refute_nil result.error_message
    refute_match(/\.rb:\d+:in/, result.error_message)
  end

  def test_search_no_keywords_error_is_structured
    result = tome.search([])
    assert result.failure?
    refute_nil result.error_message
    refute_match(/\.rb:\d+:in/, result.error_message)
  end

  def test_related_not_found_error_is_structured
    result = tome.related("INVALID")
    assert result.failure?
    refute_nil result.error_message
    refute_match(/\.rb:\d+:in/, result.error_message)
  end
end
