require "test_helper"

# AT-2.7: File source deduplication by path and system_name
class FileSourceDeduplicationTest < Minitest::Test
  include TomeDsl

  def test_same_path_and_system_name_reuses_existing_file_source
    result_a = tome.create(
      description: "Article A",
      body: "Content A",
      file_sources: [{ path: "/home/user/doc.pdf", system_name: "work-laptop" }]
    )
    assert result_a.success?, result_a.error_message

    original_fs_id = result_a.data["file_source_global_ids"].first
    assert_match BASE58_PATTERN, original_fs_id

    result_b = tome.create(
      description: "Article B",
      body: "Content B",
      file_sources: [{ path: "/home/user/doc.pdf", system_name: "work-laptop" }]
    )
    assert result_b.success?, result_b.error_message

    reused_fs_id = result_b.data["file_source_global_ids"].first

    assert_equal original_fs_id, reused_fs_id,
                 "Expected the existing file source to be reused, but a new one was created"

    assert_equal 1, Agent::Tome::FileSource.count,
                 "Expected exactly 1 file source row but found #{Agent::Tome::FileSource.count}"
  end
end
