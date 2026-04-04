require "test_helper"

# AT-3.6: Addendum with only empty body is rejected
class AddendBlankBodyTest < Minitest::Test
  include TomeDsl

  def setup
    super
    create_result = create_article!(description: "An article", body: "Initial content.")
    @article_id = create_result.article_global_id
  end

  def test_empty_body_is_rejected
    result = tome.addend(@article_id, body: "")

    refute result.success?
    assert_match(/blank/i, result.error_message)
  end

  def test_empty_body_creates_no_entry
    tome.addend(@article_id, body: "")

    article = Agent::Tome::Article.find_by(global_id: @article_id)
    assert_equal 1, article.entries.count
  end
end
