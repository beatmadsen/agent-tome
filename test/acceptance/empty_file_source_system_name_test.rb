require "test_helper"

# AT-2.18: File source with empty system_name is rejected
class EmptyFileSourceSystemNameTest < Minitest::Test
  include TomeDsl

  def test_empty_system_name_is_rejected
    result = tome.create(
      description: "Some article",
      body: "Some body",
      file_sources: [{ "path" => "/some/file", "system_name" => "" }]
    )

    refute result.success?
    assert_match(/system_name/i, result.error_message)
  end
end
