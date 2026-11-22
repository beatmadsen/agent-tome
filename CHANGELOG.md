## [Unreleased]

## [1.1.0] - 2026-11-22

### Changed

- Requires Ruby 3.3 or newer. Ruby 3.2 no longer gets security fixes, so
  `gem install` on it stays on 1.0.2.
- Arguments that used to be guessed at are now errors (see Fixed). A script
  that passed `--match` with a misspelt value, or `source-search` with an
  empty `--system`, will now get a non-zero exit instead of results.

### Fixed

- The gemspec allowed sqlite3 2.0, which Active Record 8 refuses to load.
  With sqlite3 2.0 already installed, `gem install agent-tome` succeeded
  and every command then failed. It now requires sqlite3 2.1 or newer.
- `search --match all` dropped keywords the tome had never seen before
  counting, so `search ruby nosuchword --match all` returned every article
  tagged `ruby`. It now returns nothing unless an article has every keyword.
- `search --match` with a value other than `any` or `all` searched with
  `any`, so a typo for `all` gave the broadest results instead of an error.
  A `--match` with nothing after it was treated as a keyword. Both are now
  rejected.
- `keywords _` and `keywords %` listed every keyword. Both characters now
  match literally.
- `source-search` with no argument answered with an internal Ruby error
  message. It now says a URL or file path is required. An empty
  `--system` value is rejected instead of searching for a machine with no
  name.

### Documentation

- The README and `--help` said `keywords` matches a prefix. It matches
  anywhere in the keyword, so `keywords ru` also finds `guru`.
- The README now mentions `--system` and the `AGENT_TOME_CONFIG_DIR`
  variable.

### Internal

- Tested on Ruby 4.0 with the newest activerecord, activesupport (8.1.4.1)
  and sqlite3 (2.10.2), and on Ruby 3.3 with the oldest versions the
  gemspec allows (8.0.0 and 2.1.0).
- Development requires activesupport 8.1.2 or newer, because older
  releases make the parallel test run hang under minitest 6.

## [1.0.2] - 2026-09-20

### Documentation

- The Quick Start showed `create` returning a `global_id`. It returns
  `article_global_id` and `entry_global_id`, so an agent written against the
  README was reading a key that is never there.

### Internal

- The CLI test lane (`TOME_DRIVER=cli`) had rotted and nothing ran it. It runs
  again, and `rake` now runs both it and the in-process lane, so the executable
  is covered rather than only the service objects underneath it.
- Development dependencies move to minitest 6, which extracts `minitest/mock`
  into its own gem, plus current activerecord, activesupport and sqlite3.

## [1.0.1] - 2026-04-05

### Changed

- Extract KeywordNormalizer to eliminate triple duplication across Create, Addend, and Consolidate.
- Extract KeywordLinker, WebSourceLinker, FileSourceLinker, and RelatedArticleLinker, each with unit tests, removing duplicated logic from Create and Addend.
- Extract InputValidator with unit tests, wiring Create and Addend to share validation.
- Extract ArticleFormatter for shared article summary formatting.
- Refactor Consolidate.call into named private methods.
- Add test DSL helpers and migrate all acceptance tests to use them.

## [1.0.0] - 2026-04-03

### Added

- **Article management**: Create articles with body, description, keywords, sources, and related article references. Add content addenda to existing articles.
- **Search**: Keyword-based article search with `--match any` (default) and `--match all` modes, results ordered by keyword relevance, capped at 1000.
- **Fetch**: Retrieve full article content including all entries, sources, and consolidation history.
- **Related articles**: Discover related articles via shared keywords, article references (both directions), and consolidation links (both directions).
- **Consolidation**: Merge all addenda into a single consolidated entry, preserving keywords, sources, and original article IDs for continued lookup.
- **Keyword discovery**: List keywords matching a prefix/substring for vocabulary exploration.
- **Source search**: Find articles by web URL or file path, with optional `--system` flag for scoped file path lookups.
- **Append-only SQLite store**: WAL mode and busy timeout for concurrent access. Automatic migration on first run.
- **Opaque identifiers**: All user-facing entities use randomly generated 7-character base58 global IDs. Internal integer IDs are never exposed.
- **Input validation**: Structured JSON error responses for missing fields, invalid URLs, blank bodies, oversized descriptions (350 char limit), self-references, empty stdin, and invalid JSON.
- **Data integrity**: Keyword singularisation and downcasing, web URL normalisation (strips tracking params), source deduplication, duplicate keyword and reference handling.
- **CLI**: `agent-tome` executable with JSON stdin/stdout interface, exit code 0 on success and non-zero on error.
- **Claude Code skills**: Companion `tome-lookup` and `tome-capture` skills for AI agent integration.

[Unreleased]: https://github.com/beatmadsen/agent-tome/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/beatmadsen/agent-tome/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/beatmadsen/agent-tome/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/beatmadsen/agent-tome/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/beatmadsen/agent-tome/releases/tag/v1.0.0
