## [Unreleased]

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

[Unreleased]: https://github.com/beatmadsen/agent-tome/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/beatmadsen/agent-tome/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/beatmadsen/agent-tome/releases/tag/v1.0.0
