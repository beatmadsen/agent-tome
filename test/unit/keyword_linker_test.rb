require "test_helper"

class KeywordLinkerTest < Minitest::Test
  def test_normalizes_keyword_and_creates_records
    article = Object.new
    keyword_record = Object.new

    created_terms = []
    linked_pairs = []

    find_or_create_keyword = lambda { |term:, **|
      created_terms << term
      keyword_record
    }

    find_or_create_link = lambda { |article:, keyword:, **|
      linked_pairs << { article: article, keyword: keyword }
    }

    Agent::Tome::Keyword.stub(:find_or_create_by!, find_or_create_keyword) do
      Agent::Tome::ArticleKeyword.stub(:find_or_create_by!, find_or_create_link) do
        Agent::Tome::KeywordLinker.call(article, ["Processes"])
      end
    end

    assert_equal ["process"], created_terms
    assert_equal 1, linked_pairs.size
    assert_equal article, linked_pairs.first[:article]
    assert_equal keyword_record, linked_pairs.first[:keyword]
  end

  def test_processes_multiple_keywords
    article = Object.new
    created_terms = []

    find_or_create_keyword = lambda { |term:, **|
      created_terms << term
      Object.new
    }

    Agent::Tome::Keyword.stub(:find_or_create_by!, find_or_create_keyword) do
      Agent::Tome::ArticleKeyword.stub(:find_or_create_by!, ->(**) {}) do
        Agent::Tome::KeywordLinker.call(article, ["Processes", "THREAD", "Web-Sources"])
      end
    end

    assert_equal ["process", "thread", "web-source"], created_terms
  end
end
