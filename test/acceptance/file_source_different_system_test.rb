require "test_helper"

# AT-2.8: File source with same path but different system_name creates new record
class FileSourceDifferentSystemTest < Minitest::Test
  include TomeDsl

  def test_same_path_different_system_name_creates_new_file_source
    result_a = tome.create(
      description: "Article A",
      body: "Content A",
      file_sources: [{ path: "/home/user/doc.pdf", system_name: "work-laptop" }]
    )
    assert result_a.success?, result_a.error_message

    laptop_fs_id = result_a.data["file_source_global_ids"].first
    assert_match BASE58_PATTERN, laptop_fs_id

    result_b = tome.create(
      description: "Article B",
      body: "Content B",
      file_sources: [{ path: "/home/user/doc.pdf", system_name: "home-desktop" }]
    )
    assert result_b.success?, result_b.error_message

    desktop_fs_id = result_b.data["file_source_global_ids"].first
    assert_match BASE58_PATTERN, desktop_fs_id

    refute_equal laptop_fs_id, desktop_fs_id,
                 "Expected distinct file sources for different system_names, but got the same global_id"

    assert_equal 2, Agent::Tome::FileSource.count,
                 "Expected 2 file source rows (one per system) but found #{Agent::Tome::FileSource.count}"
  end
end
