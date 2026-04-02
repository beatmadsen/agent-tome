require "test_helper"

# AT-7.7: Empty results
class RelatedEmptyResultsTest < Minitest::Test
  include TomeDsl

  def test_all_arrays_present_and_empty_when_no_relations
    result = tome.create(description: "Isolated article", body: "No relations here.")
    assert result.success?, "Setup failed: #{result.error_message}"
    id = result.article_global_id

    result = tome.related(id)
    assert result.success?, "Related failed: #{result.error_message}"

    data = result.data
    assert_equal [], data["shared_keywords"]
    assert_equal [], data["references_to"]
    assert_equal [], data["referenced_by"]
    assert_equal [], data["consolidated_from"]
    assert_equal [], data["consolidated_into"]
  end
end
