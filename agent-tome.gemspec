# frozen_string_literal: true

require_relative "lib/agent/tome/version"

Gem::Specification.new do |spec|
  spec.name = "agent-tome"
  spec.version = Agent::Tome::VERSION
  spec.authors = ["Erik T. Madsen"]
  spec.email = []

  spec.summary = "Personal knowledge base CLI backed by SQLite, designed for AI agents."
  spec.description = "A CLI tool for building and querying a personal knowledge base stored in SQLite. " \
                     "Append-only, immutable data model with keyword-based discovery. " \
                     "Includes Claude Code skills for AI agent integration."
  spec.homepage = "https://github.com/beatmadsen/agent-tome"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/beatmadsen/agent-tome"
  spec.metadata["changelog_uri"] = "https://github.com/beatmadsen/agent-tome/blob/main/CHANGELOG.md"
  spec.metadata["claude_skills_uri"] = "https://github.com/beatmadsen/claude-skills"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ ralph/ .])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 8.0"
  spec.add_dependency "activesupport", "~> 8.0"
  spec.add_dependency "sqlite3", "~> 2.0"
end
