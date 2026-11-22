require "test_helper"

# Publishing settings are easy to lose in a gemspec edit and nothing else in the
# suite touches them, so they are stated here.
class GemspecMetadataTest < Minitest::Test
  def test_requires_multi_factor_auth_to_publish
    assert_equal "true", spec.metadata["rubygems_mfa_required"]
  end

  def test_points_at_the_repository_for_source_changelog_and_issues
    assert_match %r{\Ahttps://github\.com/beatmadsen/agent-tome}, spec.homepage
    %w[source_code_uri changelog_uri bug_tracker_uri documentation_uri].each do |key|
      assert_match %r{\Ahttps://github\.com/beatmadsen/agent-tome}, spec.metadata[key].to_s, key
    end
  end

  def test_refuses_to_install_on_ruby_that_no_longer_gets_security_fixes
    refute spec.required_ruby_version.satisfied_by?(Gem::Version.new("3.2.11"))
    assert spec.required_ruby_version.satisfied_by?(Gem::Version.new("3.3.0"))
  end

  # Active Record's SQLite adapter refuses sqlite3 older than 2.1, so allowing
  # 2.0 lets the gem install and then fail on its first command.
  def test_requires_a_sqlite3_that_active_record_will_load
    sqlite3 = spec.runtime_dependencies.find { |d| d.name == "sqlite3" }

    refute sqlite3.requirement.satisfied_by?(Gem::Version.new("2.0.2"))
    assert sqlite3.requirement.satisfied_by?(Gem::Version.new("2.1.0"))
  end

  private

  def spec
    @spec ||= Gem::Specification.load(File.expand_path("../../agent-tome.gemspec", __dir__))
  end
end
