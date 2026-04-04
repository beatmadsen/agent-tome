require "test_helper"

class SourceSearchByFilePathTest < Minitest::Test
  include TomeDsl

  # AT-9.3: Search by file path (any system)
  def test_search_by_file_path_matches_across_all_systems
    file_source_work = { path: "/home/user/doc.pdf", system_name: "work-laptop" }
    file_source_home = { path: "/home/user/doc.pdf", system_name: "home-desktop" }

    result_a = create_article!(
      description: "Article with work-laptop file source",
      body: "Content A",
      file_sources: [file_source_work]
    )

    result_b = create_article!(
      description: "Article with home-desktop file source",
      body: "Content B",
      file_sources: [file_source_home]
    )

    result = tome.source_search("/home/user/doc.pdf")

    assert_success result
    global_ids = result.results.map { |r| r["global_id"] }
    assert_includes global_ids, result_a.article_global_id
    assert_includes global_ids, result_b.article_global_id
  end
end
