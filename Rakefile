# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end

desc "Run the suite against the CLI rather than the in-process service"
task :test_cli do
  ENV["TOME_DRIVER"] = "cli"
  Rake::Task[:test].reenable
  Rake::Task[:test].invoke
end

task default: %i[test test_cli]
