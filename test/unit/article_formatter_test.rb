require "test_helper"

class ArticleFormatterTest < Minitest::Test
  def test_summary_returns_base_article_fields
    keywords_relation = Minitest::Mock.new
    keywords_relation.expect(:pluck, ["ruby", "testing"], [:term])

    article = Struct.new(:global_id, :description, :keywords, :created_at).new(
      "abc1234",
      "Test article",
      keywords_relation,
      Time.utc(2026, 1, 15, 10, 30, 0)
    )

    result = Agent::Tome::ArticleFormatter.summary(article)

    assert_equal "abc1234", result["global_id"]
    assert_equal "Test article", result["description"]
    assert_equal ["ruby", "testing"], result["keywords"]
    assert_equal "2026-01-15T10:30:00Z", result["created_at"]
    keywords_relation.verify
  end

  def test_summary_merges_extra_fields
    keywords_relation = Minitest::Mock.new
    keywords_relation.expect(:pluck, [], [:term])

    article = Struct.new(:global_id, :description, :keywords, :created_at).new(
      "xyz7890",
      "Another article",
      keywords_relation,
      Time.utc(2026, 2, 1)
    )

    result = Agent::Tome::ArticleFormatter.summary(article, "matching_keyword_count" => 3)

    assert_equal 3, result["matching_keyword_count"]
    assert_equal "xyz7890", result["global_id"]
  end
end
