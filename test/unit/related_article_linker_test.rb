require "test_helper"

class RelatedArticleLinkerTest < Minitest::Test
  def test_creates_article_reference
    article = Struct.new(:global_id).new("src1234")
    target = Struct.new(:global_id).new("tgt5678")

    found_ids = []
    created_refs = []

    find_target = lambda { |global_id:|
      found_ids << global_id
      target
    }

    find_or_create_ref = lambda { |source_article:, target_article:, **|
      created_refs << { source: source_article, target: target_article }
    }

    Agent::Tome::Article.stub(:find_by!, find_target) do
      Agent::Tome::ArticleReference.stub(:find_or_create_by!, find_or_create_ref) do
        Agent::Tome::RelatedArticleLinker.call(article, ["tgt5678"])
      end
    end

    assert_equal ["tgt5678"], found_ids
    assert_equal 1, created_refs.size
    assert_equal article, created_refs.first[:source]
    assert_equal target, created_refs.first[:target]
  end

  def test_raises_on_self_reference
    article = Struct.new(:global_id).new("self123")

    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::RelatedArticleLinker.call(article, ["self123"])
    end

    assert_equal "An article cannot reference itself", error.message
  end
end
