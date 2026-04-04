require "test_helper"

# AT-13.4: Keyword vocabulary discovery
class WorkflowKeywordVocabularyTest < Minitest::Test
  include TomeDsl

  def test_keyword_vocabulary_discovery
    # Step 1: Create articles with keywords that will be singularised on storage
    create_article!(
      description: "Article about Ruby gems",
      body: "Ruby gems are packages.",
      keywords: ["ruby-gems", "ruby-threads", "rust", "python"]
    )

    # Step 2: keywords "rub" — returns ruby-gem and ruby-thread (singularised)
    result_rub = tome.keywords("rub")
    assert_success result_rub, "keywords(rub) failed: #{result_rub.error_message}"
    assert_includes result_rub.keywords, "ruby-gem"
    assert_includes result_rub.keywords, "ruby-thread"
    refute_includes result_rub.keywords, "rust"
    refute_includes result_rub.keywords, "python"

    # Step 3: keywords "ru" — returns ruby-gem, ruby-thread, and rust
    result_ru = tome.keywords("ru")
    assert_success result_ru, "keywords(ru) failed: #{result_ru.error_message}"
    assert_includes result_ru.keywords, "ruby-gem"
    assert_includes result_ru.keywords, "ruby-thread"
    assert_includes result_ru.keywords, "rust"
    refute_includes result_ru.keywords, "python"
  end
end
