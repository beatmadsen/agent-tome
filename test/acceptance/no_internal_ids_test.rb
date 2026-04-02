require "test_helper"

# AT-2.21: Internal IDs are never exposed in output
class NoInternalIdsTest < Minitest::Test
  include TomeDsl

  def test_create_output_contains_no_integer_id_fields
    result = tome.create(
      description: "Article for internal ID check",
      body: "Some content.",
      keywords: ["ruby"],
      web_sources: [{ url: "https://example.com/id-check", title: "Test" }],
      file_sources: [{ path: "/tmp/id-check.txt", system_name: "test-machine" }]
    )

    assert result.success?, "Expected success but got: #{result.error_message}"
    refute contains_integer_id?(result.data),
           "Output must not contain any integer 'id' field, got: #{result.data.inspect}"
  end

  private

  def contains_integer_id?(obj)
    case obj
    when Hash
      obj.any? do |k, v|
        (k == "id" || k == :id) && v.is_a?(Integer)
      end || obj.values.any? { |v| contains_integer_id?(v) }
    when Array
      obj.any? { |v| contains_integer_id?(v) }
    else
      false
    end
  end
end
