---
agent: claude -p --dangerously-skip-permissions --model claude-sonnet-4-6
commands:
  - name: tests
    run: cd /Users/erik.madsen/Developer/hobby/ruby/agent-tome && bundle exec rake test 2>&1 | tail -80
    timeout: 120
  - name: progress
    run: cd /Users/erik.madsen/Developer/hobby/ruby/agent-tome && cat ralph/progress.md 2>/dev/null || echo "No progress file yet"
    timeout: 10
  - name: done_check
    run: cd /Users/erik.madsen/Developer/hobby/ruby/agent-tome && test -f ralph/DONE && echo "ALL_DONE" || echo "NOT_DONE"
    timeout: 5
  - name: recent_commits
    run: cd /Users/erik.madsen/Developer/hobby/ruby/agent-tome && git log --oneline -10 2>&1
    timeout: 10
  - name: requirements
    run: cat /Users/erik.madsen/Developer/hobby/ruby/agent-tome/agent-tome-requirements.md
    timeout: 10
  - name: acceptance_tests
    run: cat /Users/erik.madsen/Developer/hobby/ruby/agent-tome/acceptance-tests.md
    timeout: 10
---

# Agent-Tome ATDD Build

You are building `agent-tome`, a Ruby gem CLI tool for a personal knowledge base backed by SQLite. You work in `/Users/erik.madsen/Developer/hobby/ruby/agent-tome`.

## Completion check

{{ commands.done_check }}

**If the output above says `ALL_DONE`, do nothing. Output "All acceptance tests implemented. Nothing to do." and exit immediately.**

## Context

### Requirements
{{ commands.requirements }}

### Acceptance Tests
{{ commands.acceptance_tests }}

### Progress
{{ commands.progress }}

### Recent Commits
{{ commands.recent_commits }}

### Test Output
{{ commands.tests }}

## Your task

You are iteration {{ ralph.iteration }} of an ATDD build loop. Each iteration implements **exactly one** acceptance test case, then commits.

### Rules

1. **Read `ralph/progress.md` first.** It tells you which acceptance test to implement next. If all tests are marked done, create the file `ralph/DONE`, commit it with message "All acceptance tests implemented", and exit.

2. **One acceptance test per iteration.** Find the next unchecked test in `ralph/progress.md`. Implement it fully, then mark it `[x]` and commit.

3. **ATDD double-loop discipline:**
   - **Outer loop:** Write/update a Minitest acceptance test in `test/acceptance/` that exercises the acceptance test case through the DSL (see below). Run it, confirm it fails (RED).
   - **Inner loop:** Write the minimal production code to make it pass. Use unit tests in `test/unit/` if the production code is non-trivial. Run all tests, confirm GREEN.
   - If all tests pass, commit and update `ralph/progress.md`.

4. **Commit on green.** Every commit must have all tests passing. Commit message format: `AT-X.Y: <short description>` (e.g., `AT-2.1: minimal article creation`). Stage specific files, not `git add -A`. Include `ralph/progress.md` in the commit. Add `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` to each commit.

5. **Never break existing tests.** If a change breaks an earlier test, fix it before committing.

6. **Ruby 3.4+ compatibility.** Do not use features removed in Ruby 3.4. Do not use frozen string literal comments (they are default in 3.4+).

### Test Framework: Minitest with Parallel Execution

Use Minitest with ActiveSupport's parallel test executor. The `test/test_helper.rb` should look like:

```ruby
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'agent/tome'

require 'minitest/autorun'

require 'active_support'
require 'active_support/testing/parallelization'
require 'active_support/testing/parallelize_executor'
require 'concurrent/utility/processor_counter'

Minitest.parallel_executor = ActiveSupport::Testing::ParallelizeExecutor.new(
  size: Concurrent.processor_count,
  with: :processes,
  threshold: 0,
)

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }
```

**Because tests run in parallel across forked processes, each test must use its own isolated temp directory and database.** No shared state between tests. The DSL's `setup`/`teardown` handles this.

Use `Rake::TestTask` in the `Rakefile` to run tests with `bundle exec rake test`. Configure it to find tests in `test/**/*_test.rb`.

### Acceptance Test DSL

All acceptance tests use a shared DSL module defined in `test/support/tome_dsl.rb`. Two protocol drivers implement it:

- **`ServiceDriver`** (`test/support/drivers/service_driver.rb`): Calls the service layer directly (Ruby method calls). Primary driver during development.
- **`CliDriver`** (`test/support/drivers/cli_driver.rb`): Shells out to the `agent-tome` CLI executable. Verifies the full stack.

The DSL should look something like this (adapt as needed):

```ruby
# test/support/tome_dsl.rb
module TomeDsl
  def setup
    @tmp_dir = Dir.mktmpdir("agent-tome-test")
    @db_path = File.join(@tmp_dir, "test.db")
    @config_dir = File.join(@tmp_dir, "config")
    FileUtils.mkdir_p(@config_dir)
    File.write(File.join(@config_dir, "config.yml"), YAML.dump("db_path" => @db_path))
    @tome_driver = build_driver
    super
  end

  def teardown
    super
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def tome
    @tome_driver
  end

  private

  def build_driver
    driver_class = ENV.fetch("TOME_DRIVER", "service") == "cli" ? CliDriver : ServiceDriver
    driver_class.new(db_path: @db_path, config_dir: @config_dir)
  end
end

# Usage in tests:
class CreateMinimalArticleTest < Minitest::Test
  include TomeDsl

  def test_creates_article_with_description_and_body
    result = tome.create(description: "How Ruby GC works", body: "Ruby uses a mark-and-sweep garbage collector.")

    assert result.success?
    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\z/, result.article_global_id)
    assert_match(/\A[1-9A-HJ-NP-Za-km-z]{7}\z/, result.entry_global_id)
  end
end
```

Each driver method returns a result object with a consistent interface (success?, error_message, plus data accessors). The service driver wraps service layer calls; the CLI driver parses JSON output and exit codes.

**Driver switching:** `TOME_DRIVER=service bundle exec rake test` (default) or `TOME_DRIVER=cli bundle exec rake test`.

### Bootstrapping (iteration 1 only)

If the gem skeleton does not exist yet (no `Gemfile`, no `lib/` directory), your first task is:

1. Create the gem skeleton: `Gemfile`, `agent-tome.gemspec`, `lib/agent/tome.rb`, `lib/agent/tome/version.rb`, `bin/agent-tome`, `Rakefile`
2. Set up the test infrastructure: `test/test_helper.rb`, `test/support/tome_dsl.rb`, `test/support/drivers/service_driver.rb`, `test/support/drivers/cli_driver.rb`, `test/support/result.rb`
3. Create `ralph/progress.md` with all acceptance tests as a checklist
4. Create the ActiveRecord migration(s) for the full schema in `db/migrate/`
5. Create all ActiveRecord models in `lib/agent/tome/models/`
6. Create the database bootstrap/connection logic
7. Then implement the first acceptance test (1.1 or whichever is first in progress.md)
8. Commit all of this together as: `Bootstrap gem skeleton, schema, models, and test infrastructure`

The gemspec should specify `required_ruby_version: ">= 3.4"`. Dependencies: `activerecord`, `activesupport`, `sqlite3`. Dev dependencies: `minitest`, `rake`, `concurrent-ruby`.

### Section 11 and 12 tests

Section 11 (Data Model Integrity) tests are schema-level integration tests. Implement them as Minitest tests that verify the migration schema directly (check column existence, index existence, constraint behaviour) — they don't need the DSL.

Section 12 (Namespace & Distribution) tests verify `require 'agent/tome'` loads the module. Implement as simple Minitest tests.

### Section 10 tests (Output & Error Conventions)

These are cross-cutting concerns. Implement them by verifying the conventions are upheld across existing tests rather than writing entirely new scenarios. Add a few targeted tests.

### Section 13 tests (End-to-End Workflows)

These combine multiple operations. Implement them as acceptance tests using the DSL, exercising the full sequence described in each workflow.

### Important implementation details

- The service layer should be a set of command classes (e.g., `Agent::Tome::Commands::Create`, `Agent::Tome::Commands::Addend`, etc.) that the CLI adapter calls.
- URL normalisation: strip `utm_*`, `fbclid`, `gclid`, `fbid`, `mc_cid`, `mc_eid` query params. Use `URI` stdlib.
- Base58 alphabet: `123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz` (no 0, O, I, l).
- Config uses the test's temp directory, not the real `~/.agent-tome/`. Each test gets an isolated database.
- The CLI driver should set `AGENT_TOME_CONFIG_DIR` env var to point to the test's temp config directory, so it doesn't touch the real home directory.
