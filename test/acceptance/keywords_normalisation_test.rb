require "test_helper"

# AT-2.3: Keywords are singularised and downcased
class KeywordsNormalisationTest < Minitest::Test
  include TomeDsl

  def test_keywords_are_singularised_and_downcased
    result = tome.create(
      description: "Keyword normalisation test",
      body: "Testing keyword normalisation rules.",
      keywords: ["Processes", "concurrent-processes", "Web-Sources", "THREAD"]
    )

    assert result.success?, "Expected success but got error: #{result.error_message}"

    expected_terms = %w[process concurrent-process web-source thread]
    article = Agent::Tome::Article.find_by!(global_id: result.article_global_id)
    actual_terms = article.keywords.pluck(:term).sort

    assert_equal expected_terms.sort, actual_terms,
                 "Expected keywords #{expected_terms.sort.inspect}, got #{actual_terms.inspect}"
  end
end
