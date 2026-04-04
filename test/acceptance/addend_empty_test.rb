require "test_helper"

# AT-3.5: Empty addendum is rejected
class AddendEmptyTest < Minitest::Test
  include TomeDsl

  def setup
    super
    create_result = create_article!(description: "An article", body: "Initial content.")
    @article_id = create_result.article_global_id
  end

  def test_empty_addendum_is_rejected
    result = tome.addend(@article_id)

    refute result.success?
    assert_match(/at least one field/i, result.error_message)
  end

  def test_empty_addendum_creates_no_entry
    tome.addend(@article_id)

    article = Agent::Tome::Article.find_by(global_id: @article_id)
    assert_equal 1, article.entries.count
  end
end
