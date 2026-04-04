require "test_helper"

# AT-2.7: File source deduplication by path and system_name
class FileSourceDeduplicationTest < Minitest::Test
  include TomeDsl

  def test_same_path_and_system_name_reuses_existing_file_source
    result_a = create_article!(
      description: "Article A",
      body: "Content A",
      file_sources: [{ path: "/home/user/doc.pdf", system_name: "work-laptop" }]
    )

    original_fs_id = result_a.data["file_source_global_ids"].first
    assert_global_id original_fs_id

    result_b = create_article!(
      description: "Article B",
      body: "Content B",
      file_sources: [{ path: "/home/user/doc.pdf", system_name: "work-laptop" }]
    )

    reused_fs_id = result_b.data["file_source_global_ids"].first

    assert_equal original_fs_id, reused_fs_id,
                 "Expected the existing file source to be reused, but a new one was created"

    assert_equal 1, Agent::Tome::FileSource.count,
                 "Expected exactly 1 file source row but found #{Agent::Tome::FileSource.count}"
  end
end
