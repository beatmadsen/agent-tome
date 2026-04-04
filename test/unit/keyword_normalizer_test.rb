require "test_helper"

class KeywordNormalizerTest < Minitest::Test
  def test_singularizes_single_word
    assert_equal "process", Agent::Tome::KeywordNormalizer.call("processes")
  end

  def test_downcases_input
    assert_equal "thread", Agent::Tome::KeywordNormalizer.call("THREAD")
  end

  def test_singularizes_only_last_segment_of_hyphenated_keyword
    assert_equal "concurrent-process", Agent::Tome::KeywordNormalizer.call("concurrent-processes")
  end

  def test_handles_multiple_hyphens
    assert_equal "multi-word-api", Agent::Tome::KeywordNormalizer.call("Multi-Word-APIs")
  end

  def test_downcases_and_singularizes_together
    assert_equal "web-source", Agent::Tome::KeywordNormalizer.call("Web-Sources")
  end

  def test_preserves_already_singular_input
    assert_equal "thread", Agent::Tome::KeywordNormalizer.call("thread")
  end
end
