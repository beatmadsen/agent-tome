require "test_helper"

# AT-10.6: No command outputs internal integer IDs
# Every command's JSON output must contain no field named `id` with an integer value.
class NoInternalIdsAllCommandsTest < Minitest::Test
  include TomeDsl

  def test_all_commands_output_no_integer_id_fields
    created = tome.create(
      description: "Article for AT-10.6 ID check",
      body: "Initial content.",
      keywords: ["ruby", "testing"],
      web_sources: [{ url: "https://example.com/at-10-6", title: "Test Source" }],
      file_sources: [{ path: "/tmp/at-10-6.txt", system_name: "test-machine" }]
    )
    assert created.success?, "create failed: #{created.error_message}"
    refute contains_integer_id?(created.data), "create output contains integer id: #{created.data.inspect}"

    article_id = created.article_global_id

    addend_result = tome.addend(article_id, body: "Addendum content.", keywords: ["gc"])
    assert addend_result.success?, "addend failed: #{addend_result.error_message}"
    refute contains_integer_id?(addend_result.data), "addend output contains integer id: #{addend_result.data.inspect}"

    search_result = tome.search(["ruby"])
    assert search_result.success?, "search failed: #{search_result.error_message}"
    refute contains_integer_id?(search_result.data), "search output contains integer id: #{search_result.data.inspect}"

    fetch_result = tome.fetch(article_id)
    assert fetch_result.success?, "fetch failed: #{fetch_result.error_message}"
    refute contains_integer_id?(fetch_result.data), "fetch output contains integer id: #{fetch_result.data.inspect}"

    related_result = tome.related(article_id)
    assert related_result.success?, "related failed: #{related_result.error_message}"
    refute contains_integer_id?(related_result.data), "related output contains integer id: #{related_result.data.inspect}"

    keywords_result = tome.keywords("rub")
    assert keywords_result.success?, "keywords failed: #{keywords_result.error_message}"
    refute contains_integer_id?(keywords_result.data), "keywords output contains integer id: #{keywords_result.data.inspect}"

    source_result = tome.source_search("https://example.com/at-10-6")
    assert source_result.success?, "source-search failed: #{source_result.error_message}"
    refute contains_integer_id?(source_result.data), "source-search output contains integer id: #{source_result.data.inspect}"

    consolidate_result = tome.consolidate(article_id, body: "Consolidated content.")
    assert consolidate_result.success?, "consolidate failed: #{consolidate_result.error_message}"
    refute contains_integer_id?(consolidate_result.data), "consolidate output contains integer id: #{consolidate_result.data.inspect}"
  end

  private

  def contains_integer_id?(obj)
    case obj
    when Hash
      obj.any? { |k, v| (k == "id" || k == :id) && v.is_a?(Integer) } ||
        obj.values.any? { |v| contains_integer_id?(v) }
    when Array
      obj.any? { |v| contains_integer_id?(v) }
    else
      false
    end
  end
end
