require "test_helper"

class SourceSearchMissingArgumentTest < Minitest::Test
  include TomeDsl

  # AT-9.8: source-search with no argument
  def test_missing_source_is_rejected_with_a_clear_message
    result = tome.source_search(nil)

    refute result.success?
    assert_match(/url or file path/i, result.error_message)
  end

  # AT-9.9: source-search with an empty --system value
  def test_empty_system_name_is_rejected
    create_article!(file_sources: [{ path: "/home/user/doc.pdf", system_name: "work-laptop" }])

    result = tome.source_search("/home/user/doc.pdf", system: "")

    refute result.success?
    assert_match(/--system/, result.error_message)
  end
end
