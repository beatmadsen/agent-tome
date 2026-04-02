require_relative "lib/agent/tome/version"

Gem::Specification.new do |spec|
  spec.name = "agent-tome"
  spec.version = Agent::Tome::VERSION
  spec.authors = ["Erik T. Madsen"]
  spec.email = []

  spec.summary = "Personal knowledge base CLI backed by SQLite, designed for AI agents."
  spec.description = "A CLI tool for building and querying a personal knowledge base stored in SQLite."
  spec.required_ruby_version = ">= 3.4"

  spec.files = Dir["lib/**/*.rb", "db/**/*.rb", "bin/*", "*.gemspec", "*.md"]
  spec.bindir = "bin"
  spec.executables = ["agent-tome"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "sqlite3", ">= 1.7"

  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "concurrent-ruby"
end
