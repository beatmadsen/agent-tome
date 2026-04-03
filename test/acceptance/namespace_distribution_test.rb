require "test_helper"

# AT-12.1: Gem provides agent-tome executable
# AT-12.2: Module namespace is Agent::Tome
class NamespaceDistributionTest < Minitest::Test
  def test_agent_tome_executable_exists
    exe_path = File.expand_path("../../exe/agent-tome", __dir__)
    assert File.exist?(exe_path), "Expected exe/agent-tome to exist"
  end

  def test_agent_tome_executable_is_executable
    exe_path = File.expand_path("../../exe/agent-tome", __dir__)
    assert File.executable?(exe_path), "Expected exe/agent-tome to be executable"
  end

  def test_gemspec_declares_agent_tome_as_executable
    gemspec_path = File.expand_path("../../agent-tome.gemspec", __dir__)
    spec = Gem::Specification.load(gemspec_path)
    assert spec, "Expected gemspec to load successfully from #{gemspec_path}"
    assert_includes spec.executables, "agent-tome", "Expected gemspec to declare 'agent-tome' as an executable"
  end

  def test_module_namespace_is_agent_tome
    assert defined?(Agent), "Expected Agent module to be defined"
    assert defined?(Agent::Tome), "Expected Agent::Tome module to be defined"
    assert_kind_of Module, Agent::Tome
  end

  def test_require_agent_tome_defines_namespace
    # require 'agent/tome' is already loaded via test_helper
    # Verify the module structure matches the gem convention
    assert Agent::Tome.is_a?(Module), "Agent::Tome must be a Module"
  end
end
