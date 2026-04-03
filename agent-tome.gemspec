# frozen_string_literal: true

require_relative "lib/agent/tome/version"

Gem::Specification.new do |spec|
  spec.name = "agent-tome"
  spec.version = Agent::Tome::VERSION
  spec.authors = ["Erik T. Madsen"]
  spec.email = []

  spec.summary = "Build a personal encyclopedia of accumulated knowledge, designed for AI agents."
  spec.description = "A knowledge base that grows with every session your AI agent runs. " \
                     "Findings accumulate in a persistent, append-only store, so your agent " \
                     "can build on what it already knows instead of starting from scratch. " \
                     "Keyword-indexed and searchable from any CLI."
  spec.homepage = "https://github.com/beatmadsen/agent-tome"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/beatmadsen/agent-tome/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ ralph/ .]) ||
          f.match?(/\A(Gemfile|Rakefile|acceptance-tests\.md|agent-tome-requirements\.md)\z/)
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 8.0"
  spec.add_dependency "activesupport", "~> 8.0"
  spec.add_dependency "sqlite3", "~> 2.0"
end
