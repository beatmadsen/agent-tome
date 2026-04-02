require "test_helper"

# AT-2.17: File source with empty path is rejected
class EmptyFileSourcePathTest < Minitest::Test
  include TomeDsl

  def test_empty_path_is_rejected
    result = tome.create(
      description: "Some article",
      body: "Some body",
      file_sources: [{ "path" => "", "system_name" => "laptop" }]
    )

    refute result.success?
    assert_match(/path/i, result.error_message)
  end
end
