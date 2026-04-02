require "test_helper"

class SourceSearchWithSystemFlagTest < Minitest::Test
  include TomeDsl

  # AT-9.4: Search by file path with --system flag
  def test_system_flag_restricts_results_to_specified_system
    file_source_work = { path: "/home/user/doc.pdf", system_name: "work-laptop" }
    file_source_home = { path: "/home/user/doc.pdf", system_name: "home-desktop" }

    result_a = tome.create(
      description: "Article with work-laptop file source",
      body: "Content A",
      file_sources: [file_source_work]
    )
    assert result_a.success?

    result_b = tome.create(
      description: "Article with home-desktop file source",
      body: "Content B",
      file_sources: [file_source_home]
    )
    assert result_b.success?

    result = tome.source_search("/home/user/doc.pdf", system: "work-laptop")

    assert result.success?
    global_ids = result.results.map { |r| r["global_id"] }
    assert_includes global_ids, result_a.article_global_id
    refute_includes global_ids, result_b.article_global_id
  end
end
