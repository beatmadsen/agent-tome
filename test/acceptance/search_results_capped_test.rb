require "test_helper"

# AT-4.7: Search results capped at 1000
class SearchResultsCappedTest < Minitest::Test
  include TomeDsl

  def test_search_returns_at_most_1000_results
    # Seed 1001 articles directly via ActiveRecord to keep the test fast
    kw = Agent::Tome::Keyword.create!(term: "ruby")

    now = Time.now.utc
    1001.times do |i|
      gid = generate_unique_global_id
      article = Agent::Tome::Article.create!(
        global_id: gid,
        description: "Article #{i}",
        created_at: now
      )
      Agent::Tome::ArticleKeyword.create!(article: article, keyword: kw)
      Agent::Tome::Entry.create!(article: article, body: "body #{i}", created_at: now)
    end

    result = tome.search(["ruby"])

    assert result.success?, result.error_message
    assert result.data["results"].length <= 1000,
           "Expected at most 1000 results, got #{result.data["results"].length}"
  end

  private

  BASE58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

  def generate_unique_global_id
    loop do
      id = Array.new(7) { BASE58[rand(58)] }.join
      return id unless Agent::Tome::Article.exists?(global_id: id)
    end
  end
end
