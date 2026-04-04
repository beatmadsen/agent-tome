require "test_helper"

# AT-2.20: Global IDs are 7-character base58 strings
class GlobalIdsBase58Test < Minitest::Test
  include TomeDsl

  def test_all_returned_global_ids_are_7_char_base58
    result = tome.create(
      description: "Article for ID format verification",
      body: "Some content for testing.",
      keywords: ["testing"],
      web_sources: [
        { url: "https://example.com/id-test", title: "ID Test" }
      ],
      file_sources: [
        { path: "/tmp/test-file.txt", system_name: "test-machine" }
      ]
    )

    assert_success result

    assert_global_id result.article_global_id,
                     "article_global_id must be a 7-character base58 string"
    assert_global_id result.entry_global_id,
                     "entry_global_id must be a 7-character base58 string"

    result.data["web_source_global_ids"].each do |gid|
      assert_global_id gid,
                       "web_source global_id '#{gid}' must be a 7-character base58 string"
    end

    result.data["file_source_global_ids"].each do |gid|
      assert_global_id gid,
                       "file_source global_id '#{gid}' must be a 7-character base58 string"
    end
  end
end
