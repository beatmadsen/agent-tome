require "test_helper"

# AT-3.4: Addendum with all fields
class AddendAllFieldsTest < Minitest::Test
  include TomeDsl

  def test_addendum_with_all_fields_processes_everything
    create_a = create_article!(description: "Article A", body: "Body of A.")
    article_a_id = create_a.article_global_id

    create_b = create_article!(description: "Article B", body: "Body of B.")
    article_b_id = create_b.article_global_id

    result = tome.addend(
      article_a_id,
      body: "Additional finding with all fields.",
      keywords: ["performance", "tuning"],
      web_sources: [{ url: "https://example.com/all-fields", title: "All Fields Source" }],
      file_sources: [{ path: "/home/user/notes.md", system_name: "work-laptop" }],
      related_article_ids: [article_b_id]
    )

    assert_success result
    assert_global_id result.entry_global_id,
                     "entry_global_id should be a 7-character base58 string"

    article_a = Agent::Tome::Article.find_by(global_id: article_a_id)

    # Entry created with the given body
    new_entry = article_a.entries.find_by(global_id: result.entry_global_id)
    refute_nil new_entry, "New entry should exist in database"
    assert_equal "Additional finding with all fields.", new_entry.body

    # Keywords added to article
    keyword_terms = article_a.keywords.pluck(:term)
    assert_includes keyword_terms, "performance"
    assert_includes keyword_terms, "tuning"

    # Web source linked to the new entry
    assert_equal 1, new_entry.web_sources.count
    assert_equal "https://example.com/all-fields", new_entry.web_sources.first.url

    # File source linked to the new entry
    assert_equal 1, new_entry.file_sources.count
    assert_equal "/home/user/notes.md", new_entry.file_sources.first.path
    assert_equal "work-laptop", new_entry.file_sources.first.system_name

    # ArticleReference created from A to B
    ref = Agent::Tome::ArticleReference.joins(:target_article)
                                       .where(source_article: article_a,
                                              articles: { global_id: article_b_id })
                                       .first
    refute_nil ref, "ArticleReference from A to B should exist"
  end
end
