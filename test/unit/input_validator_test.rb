require "test_helper"

class InputValidatorTest < Minitest::Test
  def test_validate_keywords_rejects_non_array
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_keywords!("not an array")
    end
    assert_equal "keywords must be an array", error.message
  end

  def test_validate_keywords_rejects_empty_string_keyword
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_keywords!(["  "])
    end
    assert_equal "keyword must be a non-empty string", error.message
  end

  def test_validate_keywords_accepts_valid_keywords
    Agent::Tome::InputValidator.validate_keywords!(["ruby", "testing"])
  end

  def test_validate_web_sources_rejects_non_array
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_web_sources!("not an array")
    end
    assert_equal "web_sources must be an array", error.message
  end

  def test_validate_web_sources_rejects_missing_url
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_web_sources!([{}])
    end
    assert_equal "web_source url is required", error.message
  end

  def test_validate_web_sources_rejects_invalid_url
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_web_sources!([{"url" => "not-a-url"}])
    end
    assert_match(/invalid URL/, error.message)
  end

  def test_validate_file_sources_rejects_non_array
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_file_sources!("not an array")
    end
    assert_equal "file_sources must be an array", error.message
  end

  def test_validate_file_sources_rejects_empty_path
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_file_sources!([{"path" => "", "system_name" => "local"}])
    end
    assert_equal "file_source path cannot be empty", error.message
  end

  def test_validate_file_sources_rejects_empty_system_name
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_file_sources!([{"path" => "/tmp/f.md", "system_name" => ""}])
    end
    assert_equal "file_source system_name cannot be empty", error.message
  end

  def test_validate_related_ids_rejects_non_array
    error = assert_raises(Agent::Tome::ValidationError) do
      Agent::Tome::InputValidator.validate_related_ids!("not an array")
    end
    assert_equal "related_article_ids must be an array", error.message
  end

  def test_validate_related_ids_rejects_nonexistent_article
    Agent::Tome::Article.stub(:exists?, false) do
      error = assert_raises(Agent::Tome::ValidationError) do
        Agent::Tome::InputValidator.validate_related_ids!(["nonexistent-id"])
      end
      assert_match(/Referenced article not found/, error.message)
    end
  end

  def test_validate_related_ids_accepts_existing_article
    Agent::Tome::Article.stub(:exists?, true) do
      Agent::Tome::InputValidator.validate_related_ids!(["existing-id"])
    end
  end
end
