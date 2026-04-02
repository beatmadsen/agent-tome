# Agent-Tome Acceptance Tests

These test cases cover the full requirements surface of agent-tome. Each test describes a scenario, the input, and the expected outcome. Tests assume a clean database unless stated otherwise.

---

## 1. Configuration & Bootstrap

### 1.1 First run creates config directory
**Given** `~/.agent-tome/` does not exist
**When** any `agent-tome` command is run
**Then** `~/.agent-tome/` is created, and `~/.agent-tome/config.yml` exists with a `db_path` key.

### 1.2 First run creates database and runs all migrations
**Given** a valid `config.yml` with `db_path: /tmp/test-tome.db` and no database file exists at that path
**When** `agent-tome search ruby` is run
**Then** `/tmp/test-tome.db` is created, all tables exist (`articles`, `entries`, `keywords`, `article_keywords`, `web_sources`, `file_sources`, `entry_web_sources`, `entry_file_sources`, `article_references`, `consolidation_links`, `schema_migrations`), and the command completes with exit code 0.

### 1.3 Pending migrations are applied automatically on invocation
**Given** a database created by an older gem version (missing a table or column that a newer migration adds)
**When** any `agent-tome` command is run with the newer gem version
**Then** the pending migration(s) are applied before the command executes, and the command succeeds.

### 1.4 Migration state is tracked in the database
**Given** all migrations have been applied
**When** any `agent-tome` command is run
**Then** no migrations are re-applied; the `schema_migrations` table records each applied version exactly once.

### 1.5 Missing config file produces a clear error
**Given** `~/.agent-tome/` exists but `config.yml` is absent
**When** any `agent-tome` command is run
**Then** exit code is non-zero, JSON error indicating the config file is missing.

### 1.6 Missing db_path in config produces a clear error
**Given** `~/.agent-tome/config.yml` exists but contains no `db_path` key
**When** any `agent-tome` command is run
**Then** exit code is non-zero, JSON error indicating `db_path` is not configured.

### 1.7 Unwritable db_path produces a clear error
**Given** `config.yml` has `db_path: /root/no-access/tome.db` (a path the user cannot write to)
**When** any `agent-tome` command is run
**Then** exit code is non-zero, JSON error indicating the database path is not writable.

---

## 2. `agent-tome create`

### 2.1 Minimal article creation
**Given** an empty database
**When** `agent-tome create` receives via stdin:
```json
{ "description": "How Ruby GC works", "body": "Ruby uses a mark-and-sweep garbage collector." }
```
**Then** exit code is 0, output is JSON containing:
- `article_global_id`: a 7-character base58 string
- `entry_global_id`: a different 7-character base58 string
- No source IDs in the output

And in the database:
- One row in `articles` with the given description and a generated `global_id`
- One row in `entries` linked to that article, with the given body
- `created_at` is set on both records

### 2.2 Article with all optional fields
**Given** an empty database
**When** `agent-tome create` receives via stdin:
```json
{
  "description": "Concurrency in Ruby",
  "body": "Ruby has threads and fibers.",
  "keywords": ["concurrency", "Ruby", "threads"],
  "web_sources": [
    { "url": "https://ruby-doc.org/concurrency", "title": "Ruby Concurrency Docs", "fetched_at": "2025-06-01T12:00:00Z" }
  ],
  "file_sources": [
    { "path": "/home/user/notes/ruby-concurrency.md", "system_name": "work-laptop" }
  ]
}
```
**Then** exit code is 0, output JSON includes `article_global_id`, `entry_global_id`, and global IDs for the web source and file source. In the database:
- Keywords "concurrency", "ruby", "thread" exist in `keywords` (downcased, singularised)
- `article_keywords` links all three to the article
- One `web_sources` row with the normalised URL, title, and fetched_at
- One `file_sources` row with path and system_name
- `entry_web_sources` links the entry to the web source
- `entry_file_sources` links the entry to the file source

### 2.3 Keywords are singularised and downcased
**Given** an empty database
**When** `agent-tome create` receives keywords `["Processes", "concurrent-processes", "Web-Sources", "THREAD"]`
**Then** the `keywords` table contains: `"process"`, `"concurrent-process"`, `"web-source"`, `"thread"` (singularisation applies to last word only, all downcased).

### 2.4 Keyword deduplication across articles
**Given** an article already exists with keyword `"ruby"`
**When** `agent-tome create` is called with keyword `"Ruby"`
**Then** no new row is inserted into `keywords`; the existing `"ruby"` keyword row is reused. A new `article_keywords` row links the new article to the existing keyword.

### 2.5 Web source deduplication by normalised URL
**Given** a web source already exists with URL `https://example.com/page`
**When** `agent-tome create` is called with web source URL `https://example.com/page?utm_source=twitter&utm_medium=social`
**Then** the tracking parameters are stripped, the URL normalises to `https://example.com/page`, the existing web source row is reused, and the output returns the existing web source's global ID.

### 2.6 Web source URL normalisation preserves non-tracking query params
**Given** an empty database
**When** `agent-tome create` is called with web source URL `https://example.com/search?q=ruby&page=2&utm_campaign=test`
**Then** the stored URL is `https://example.com/search?q=ruby&page=2` (utm_campaign stripped, other params preserved).

### 2.7 File source deduplication by path and system_name
**Given** a file source exists with `path: "/home/user/doc.pdf"` and `system_name: "work-laptop"`
**When** `agent-tome create` is called with the same path and system_name
**Then** the existing file source is reused.

### 2.8 File source with same path but different system_name creates new record
**Given** a file source exists with `path: "/home/user/doc.pdf"` and `system_name: "work-laptop"`
**When** `agent-tome create` is called with `path: "/home/user/doc.pdf"` and `system_name: "home-desktop"`
**Then** a new file source row is created with its own global_id.

### 2.9 Related article IDs create ArticleReference records
**Given** an article exists with global_id `"Ab3xK9m"`
**When** `agent-tome create` is called with `"related_article_ids": ["Ab3xK9m"]`
**Then** an `article_references` row is created with the new article as source and the referenced article as target.

### 2.10 Related article ID that does not exist is rejected
**Given** no article with global_id `"INVALID"` exists
**When** `agent-tome create` is called with `"related_article_ids": ["INVALID"]`
**Then** exit code is non-zero, output is a JSON error indicating the referenced article does not exist. No records are created (transaction rolled back).

### 2.22 Self-referencing related_article_ids is rejected
**Given** article A exists
**When** `agent-tome addend <A's global_id>` receives `{ "related_article_ids": ["<A's global_id>"] }`
**Then** exit code is non-zero, JSON error indicating an article cannot reference itself.

### 2.11 Description exceeding 350 characters is rejected
**When** `agent-tome create` receives a description that is 351 characters long
**Then** exit code is non-zero, output is a JSON error about description length.

### 2.12 Missing description is rejected
**When** `agent-tome create` receives `{ "body": "Some content" }` (no description)
**Then** exit code is non-zero, output is a JSON error about missing description.

### 2.13 Missing body is rejected
**When** `agent-tome create` receives `{ "description": "Something" }` (no body)
**Then** exit code is non-zero, output is a JSON error about missing body.

### 2.14 Blank/whitespace-only body is rejected
**When** `agent-tome create` receives `{ "description": "Something", "body": "   " }`
**Then** exit code is non-zero, output is a JSON error about body being blank.

### 2.15 Empty keyword string is rejected
**When** `agent-tome create` receives `{ "description": "X", "body": "Y", "keywords": ["valid", ""] }`
**Then** exit code is non-zero, output is a JSON error about invalid keyword.

### 2.16 Invalid web source URL is rejected
**When** `agent-tome create` receives a web source with `"url": "not-a-url"`
**Then** exit code is non-zero, output is a JSON error about invalid URL.

### 2.17 File source with empty path is rejected
**When** `agent-tome create` receives a file source with `"path": ""` and `"system_name": "laptop"`
**Then** exit code is non-zero, output is a JSON error about empty path.

### 2.18 File source with empty system_name is rejected
**When** `agent-tome create` receives a file source with `"path": "/some/file"` and `"system_name": ""`
**Then** exit code is non-zero, output is a JSON error about empty system_name.

### 2.19 Description at exactly 350 characters is accepted
**When** `agent-tome create` receives a description that is exactly 350 characters
**Then** exit code is 0, article is created successfully.

### 2.20 Global IDs are 7-character base58 strings
**When** `agent-tome create` is called successfully
**Then** all returned global IDs match the pattern `[1-9A-HJ-NP-Za-km-z]{7}` (base58 charset, 7 characters).

### 2.21 Internal IDs are never exposed in output
**When** `agent-tome create` is called successfully
**Then** the output JSON contains no integer `id` fields — only `global_id` values.

---

## 3. `agent-tome addend`

### 3.1 Add content addendum to existing article
**Given** an article exists with global_id `"Ab3xK9m"`
**When** `agent-tome addend Ab3xK9m` receives via stdin:
```json
{ "body": "Additional finding: GC can be tuned via environment variables." }
```
**Then** exit code is 0, output JSON includes `entry_global_id`. In the database: a new entry is linked to the article with the given body.

### 3.2 Add keywords via addendum
**Given** an article exists with global_id `"Ab3xK9m"` and has keyword `"ruby"`
**When** `agent-tome addend Ab3xK9m` receives:
```json
{ "keywords": ["gc", "performance"] }
```
**Then** exit code is 0. Keywords `"gc"` and `"performance"` are added to the `keywords` table (if not already present) and linked to the article via `article_keywords`. An entry is created with null body. The entry's global_id is returned.

### 3.3 Metadata-only addendum (no body, just sources)
**Given** an article exists
**When** `agent-tome addend <id>` receives:
```json
{ "web_sources": [{ "url": "https://example.com/new-source", "title": "New" }] }
```
**Then** exit code is 0. An entry is created with null body. The web source is created and linked to the entry.

### 3.4 Addendum with all fields
**Given** an article exists
**When** `agent-tome addend <id>` receives body, keywords, web_sources, file_sources, and related_article_ids (referencing another existing article)
**Then** all are processed: entry created with body, keywords added to article, sources linked to entry, article_reference created.

### 3.5 Empty addendum is rejected
**When** `agent-tome addend <id>` receives:
```json
{ "keywords": [], "web_sources": [], "file_sources": [], "related_article_ids": [] }
```
**Then** exit code is non-zero, JSON error indicating at least one field must be substantively present.

### 3.6 Addendum with only empty body is rejected
**When** `agent-tome addend <id>` receives:
```json
{ "body": "" }
```
**Then** exit code is non-zero, JSON error about body being blank.

### 3.7 Addendum to non-existent article is rejected
**When** `agent-tome addend INVALID` is called
**Then** exit code is non-zero, JSON error indicating article not found.

### 3.8 Duplicate keyword on addendum is idempotent
**Given** an article already has keyword `"ruby"`
**When** `agent-tome addend <id>` receives `{ "keywords": ["ruby"] }`
**Then** exit code is 0. No duplicate `article_keywords` row is created (or the unique constraint prevents it gracefully). The addendum succeeds.

### 3.9 Related article IDs on addendum
**Given** articles A and B exist
**When** `agent-tome addend A` receives `{ "related_article_ids": ["<B's global_id>"] }`
**Then** an `article_references` row is created linking A to B.

---

## 4. `agent-tome search`

### 4.1 Search with default match mode (any)
**Given** articles exist:
- Article A with keywords `["ruby", "gc"]`
- Article B with keywords `["ruby", "thread"]`
- Article C with keywords `["python", "gc"]`
**When** `agent-tome search ruby gc`
**Then** exit code is 0, output JSON has `results` array containing articles A, B, and C. Article A appears first (matches 2 keywords). The order of B and C (1 match each) is unspecified. Each result includes `global_id`, `description`, `keywords`, `matching_keyword_count`, and `created_at`.

### 4.2 Search with --match all
**Given** same data as 4.1
**When** `agent-tome search ruby gc --match all`
**Then** results contain only Article A (the only one with both `"ruby"` and `"gc"`).

### 4.3 Search with --match any (explicit)
**Given** same data as 4.1
**When** `agent-tome search ruby gc --match any`
**Then** same results as 4.1.

### 4.4 Search results ordered by matching keyword count descending
**Given** articles exist:
- Article A with keywords `["ruby", "gc", "performance"]`
- Article B with keywords `["ruby"]`
**When** `agent-tome search ruby gc performance`
**Then** Article A appears before Article B (3 matches vs 1 match).

### 4.5 Search keywords are normalised before matching
**When** `agent-tome search Threads Processes`
**Then** the search matches against `"thread"` and `"process"` (singularised, downcased).

### 4.6 Search with no matching results
**When** `agent-tome search nonexistent-keyword`
**Then** exit code is 0, output is `{ "results": [] }`.

### 4.7 Search results capped at 1000
**Given** more than 1000 articles match the keyword `"ruby"`
**When** `agent-tome search ruby`
**Then** output contains at most 1000 results.

### 4.8 Search result format
**When** a search returns results
**Then** each result object contains exactly: `global_id` (string), `description` (string), `keywords` (array of strings), `matching_keyword_count` (integer), `created_at` (ISO 8601 datetime string). No internal IDs are exposed.

### 4.9 Search with no keywords
**When** `agent-tome search` is run with no keyword arguments
**Then** exit code is non-zero, JSON error indicating at least one keyword is required.

---

## 5. `agent-tome fetch`

### 5.1 Fetch a simple article
**Given** an article exists with one entry, no sources, keyword `"ruby"`
**When** `agent-tome fetch <global_id>`
**Then** exit code is 0, output JSON includes:
- `global_id`, `description`, `created_at`
- `keywords`: `["ruby"]`
- `entries`: array with one entry containing `global_id`, `body`, `created_at`, `web_sources: []`, `file_sources: []`
- No `consolidated_from` field (since this article was not created via consolidation)

### 5.2 Fetch article with multiple entries
**Given** an article was created and then two addenda were added
**When** `agent-tome fetch <global_id>`
**Then** `entries` array contains three entries in chronological order (oldest first).

### 5.3 Fetch article with sources on entries
**Given** an article's entries have web sources and file sources attached
**When** `agent-tome fetch <global_id>`
**Then** each entry's `web_sources` array contains objects with `global_id`, `url`, `title`, `fetched_at`. Each entry's `file_sources` array contains objects with `global_id`, `path`, `system_name`.

### 5.4 Fetch consolidated article includes consolidated_from
**Given** an article was created via `agent-tome consolidate`
**When** `agent-tome fetch <new_article_global_id>`
**Then** output includes `consolidated_from` with `global_id` and `description` of the old (re-IDed) article.

### 5.5 Fetch non-existent article
**When** `agent-tome fetch INVALID`
**Then** exit code is non-zero, JSON error indicating article not found.

---

## 6. `agent-tome consolidate`

### 6.1 Basic consolidation
**Given** article X exists with global_id `"OrigID1"`
**When** `agent-tome consolidate OrigID1` receives via stdin:
```json
{ "body": "Consolidated content combining all entries." }
```
**Then** exit code is 0. Output includes the new article's global_id and the old article's new global_id. In the database:
- The new article now has global_id `"OrigID1"` (took over the original's ID)
- The old article has a newly generated global_id (different from `"OrigID1"`)
- A `consolidation_links` row links new_article to old_article
- The new article has one entry with the consolidated body

### 6.2 Consolidation copies keywords
**Given** article X has keywords `["ruby", "gc", "performance"]`
**When** `agent-tome consolidate <X's global_id>` is called
**Then** the new article has the same keywords `["ruby", "gc", "performance"]` linked via `article_keywords`.

### 6.3 Consolidation does not migrate ArticleReferences
**Given** article X has an ArticleReference to article Y
**When** `agent-tome consolidate <X's global_id>` is called
**Then** the ArticleReference still points from old-X (now re-IDed) to Y. The new article has no ArticleReferences (except via the consolidation link).

### 6.4 Consolidation with updated description
**Given** article X has description `"Old description"`
**When** `agent-tome consolidate <X's global_id>` receives:
```json
{ "body": "New merged content", "description": "Updated description" }
```
**Then** the new article has description `"Updated description"`.

### 6.5 Consolidation without description keeps original
**Given** article X has description `"Original description"`
**When** `agent-tome consolidate <X's global_id>` receives:
```json
{ "body": "New merged content" }
```
**Then** the new article has description `"Original description"`.

### 6.6 Consolidation requires body
**When** `agent-tome consolidate <id>` receives `{ "description": "Updated" }` (no body)
**Then** exit code is non-zero, JSON error about missing body.

### 6.6b Consolidation rejects whitespace-only body
**When** `agent-tome consolidate <id>` receives `{ "body": "   " }`
**Then** exit code is non-zero, JSON error about body being blank.

### 6.6c Consolidation rejects description exceeding 350 characters
**When** `agent-tome consolidate <id>` receives `{ "body": "Content", "description": "<351 chars>" }`
**Then** exit code is non-zero, JSON error about description length.

### 6.7 Fetching via original ID after consolidation returns new article
**Given** article was consolidated — new article took over original global_id
**When** `agent-tome fetch <original_global_id>`
**Then** returns the new consolidated article's content (with `consolidated_from` pointing to the old article).

### 6.8 Fetching old article by its new ID still works
**Given** article was consolidated — old article received a new global_id
**When** `agent-tome fetch <old_article_new_global_id>`
**Then** returns the old article with all its original entries.

### 6.9 Consolidation of non-existent article
**When** `agent-tome consolidate INVALID` is called
**Then** exit code is non-zero, JSON error indicating article not found.

---

## 7. `agent-tome related`

### 7.1 Related via shared keywords
**Given** articles A (keywords: `["ruby", "gc", "performance"]`) and B (keywords: `["ruby", "gc", "python"]`)
**When** `agent-tome related <A's global_id>`
**Then** output `shared_keywords` array includes article B with `shared_keyword_count: 2`. Article A does not appear in its own results.

### 7.2 Related via shared keywords ordering
**Given** articles A (keywords: `["ruby", "gc", "performance"]`), B (keywords: `["ruby", "gc"]`), C (keywords: `["ruby"]`)
**When** `agent-tome related <A's global_id>`
**Then** `shared_keywords` array has B before C (2 shared vs 1 shared).

### 7.3 Related via ArticleReference (references_to)
**Given** article A was created with `related_article_ids: [B's global_id]`
**When** `agent-tome related <A's global_id>`
**Then** `references_to` array includes article B with `global_id`, `description`, `keywords`, `created_at`. `referenced_by` does not include B.

### 7.3b Related via ArticleReference (referenced_by)
**Given** article A was created with `related_article_ids: [B's global_id]` (A is source, B is target in the database)
**When** `agent-tome related <B's global_id>`
**Then** `referenced_by` array includes article A. `references_to` does not include A.

### 7.4 Related via ConsolidationLink (consolidated_from)
**Given** article N was consolidated from article O
**When** `agent-tome related <N's global_id>`
**Then** `consolidated_from` array includes article O.

### 7.5 Related via ConsolidationLink (consolidated_into)
**Given** article N was consolidated from article O
**When** `agent-tome related <O's global_id>`
**Then** `consolidated_into` array includes article N.

### 7.6 Article appears in multiple relation arrays
**Given** articles A and B share keyword `"ruby"` AND A has an ArticleReference to B
**When** `agent-tome related <A's global_id>`
**Then** article B appears in both `shared_keywords` and `references_to`.

### 7.7 Empty results
**Given** an article with no shared keywords, no references, no consolidation links
**When** `agent-tome related <global_id>`
**Then** exit code is 0, output has all five arrays present but empty: `shared_keywords: []`, `references_to: []`, `referenced_by: []`, `consolidated_from: []`, `consolidated_into: []`.

### 7.8 Shared keywords capped at 100
**Given** more than 100 articles share a keyword with article A
**When** `agent-tome related <A's global_id>`
**Then** `shared_keywords` contains at most 100 entries.

### 7.9 Related for non-existent article
**When** `agent-tome related INVALID`
**Then** exit code is non-zero, JSON error indicating article not found.

---

## 8. `agent-tome keywords`

### 8.1 Keywords matching a prefix
**Given** keywords exist: `"ruby"`, `"rust"`, `"python"`, `"runtime"`, `"guru"`
**When** `agent-tome keywords ru`
**Then** exit code is 0, output includes `"ruby"`, `"rust"`, `"runtime"`. Whether `"guru"` is included depends on whether matching is prefix-only or substring. (To be decided during implementation — update this test accordingly.)

### 8.2 No matching keywords
**When** `agent-tome keywords zzz`
**Then** exit code is 0, output: `{ "keywords": [] }`.

### 8.3 Case-insensitive matching
**Given** keyword `"ruby"` exists
**When** `agent-tome keywords RU`
**Then** output includes `"ruby"`.

### 8.4 No argument provided
**When** `agent-tome keywords` is run with no argument
**Then** exit code is non-zero, JSON error indicating a prefix/substring argument is required.

---

## 9. `agent-tome source-search`

### 9.1 Search by URL
**Given** an entry has web source with URL `https://ruby-doc.org/concurrency`
**When** `agent-tome source-search https://ruby-doc.org/concurrency`
**Then** exit code is 0, results include the article(s) linked to that web source.

### 9.2 URL is normalised before matching
**Given** a web source stored as `https://example.com/page`
**When** `agent-tome source-search "https://example.com/page?utm_source=twitter"`
**Then** tracking params are stripped, and the article is found.

### 9.3 Search by file path (any system)
**Given** file sources exist:
- path: `/home/user/doc.pdf`, system: `"work-laptop"`
- path: `/home/user/doc.pdf`, system: `"home-desktop"`
**When** `agent-tome source-search /home/user/doc.pdf`
**Then** results include articles linked to both file sources (matches path across all systems).

### 9.4 Search by file path with --system flag
**Given** same data as 9.3
**When** `agent-tome source-search /home/user/doc.pdf --system work-laptop`
**Then** results include only articles linked to the `"work-laptop"` file source.

### 9.5 No matching source
**When** `agent-tome source-search https://nonexistent.example.com`
**Then** exit code is 0, results array is empty.

### 9.6 Output format
**When** `agent-tome source-search` returns results
**Then** each result includes `global_id`, `description`, `keywords`, and `created_at`. No `matching_keyword_count` field (source-search does not match on keywords).

### 9.7 URL vs file path disambiguation
**When** `agent-tome source-search https://example.com/page`
**Then** the argument is treated as a URL (matched against web sources).
**When** `agent-tome source-search /home/user/doc.pdf`
**Then** the argument is treated as a file path (matched against file sources).
The heuristic is: arguments beginning with `http://` or `https://` are URLs; all others are file paths.

---

## 10. Output & Error Conventions

### 10.1 All commands output JSON to stdout
**When** any `agent-tome` command is run (success or failure)
**Then** stdout contains valid JSON.

### 10.2 Success exit code is 0
**When** any command succeeds
**Then** exit code is 0.

### 10.3 Error exit code is non-zero
**When** any command fails (validation error, not found, etc.)
**Then** exit code is non-zero.

### 10.4 Errors are reported as structured JSON
**When** a validation error occurs
**Then** the output is a JSON object with a clear error message (not a stack trace or unstructured text).

### 10.5 Invalid JSON on stdin is rejected
**When** `agent-tome create` receives `{invalid json` on stdin
**Then** exit code is non-zero, JSON error about malformed input.

### 10.7 Empty stdin is rejected
**When** `agent-tome create` receives empty input (e.g., piped from `/dev/null`)
**Then** exit code is non-zero, JSON error about missing input.

### 10.6 No command outputs internal integer IDs
**When** any command outputs JSON
**Then** no field named `id` with an integer value appears. All identifiers are `global_id` strings.

---

## 11. Data Model Integrity

These tests verify schema-level constraints. They are integration tests against the migration/schema rather than CLI acceptance tests.

### 11.1 Global IDs are unique within each table
**Given** many articles, entries, web sources, and file sources are created
**Then** each table's `global_id` column has a unique index. A duplicate `global_id` within the same table causes a hard failure (unique constraint violation) and the caller retries.

### 11.2 No records have updated_at
**Given** any record in any table
**Then** no `updated_at` column exists on any table. Only `created_at` is present.

### 11.3 Duplicate keyword on same article is handled gracefully
**Given** an article already has keyword `"ruby"`
**When** `agent-tome addend <id>` adds keyword `"ruby"` again
**Then** the command succeeds without creating a duplicate `article_keywords` row. (Covered by CLI test 3.8; this confirms the schema constraint underpinning it.)

### 11.4 Duplicate source link on same entry is prevented
**When** the application attempts to link the same web source (or file source) to the same entry twice
**Then** the unique constraint on `entry_web_sources (entry_id, web_source_id)` (or `entry_file_sources`) prevents the duplicate.

### 11.5 Duplicate article reference is prevented
**Given** an ArticleReference from A to B already exists
**When** the application attempts to create another reference from A to B
**Then** the unique constraint on `article_references (source_article_id, target_article_id)` prevents the duplicate.

---

## 12. Namespace & Distribution

### 12.1 Gem provides agent-tome executable
**When** `gem install agent-tome` completes
**Then** the `agent-tome` command is available on the PATH.

### 12.2 Module namespace is Agent::Tome
**When** `require 'agent/tome'` is evaluated
**Then** the `Agent::Tome` module is defined.

---

## 13. End-to-End Workflows

### 13.1 Create, addend, search, fetch lifecycle
1. `agent-tome create` with description "Ruby GC internals", body "Mark and sweep", keywords `["ruby", "gc"]` -- succeeds, returns article ID X
2. `agent-tome addend X` with body "Generational GC added in 2.1", keywords `["performance"]` -- succeeds
3. `agent-tome search ruby gc` -- returns article X with `matching_keyword_count: 2`
4. `agent-tome fetch X` -- returns article with 2 entries (original + addendum), keywords `["ruby", "gc", "performance"]`

### 13.2 Create, consolidate, fetch lifecycle
1. Create article with 3 addenda
2. `agent-tome consolidate <id>` with merged body -- succeeds, returns new and old IDs
3. `agent-tome fetch <original_id>` -- returns the new consolidated article with `consolidated_from`
4. `agent-tome fetch <old_article_new_id>` -- returns the old article with all original entries
5. `agent-tome related <original_id>` -- `consolidated_from` includes the old article

### 13.3 Source deduplication across articles
1. Create article A with web source `https://ruby-doc.org/page`
2. Create article B with web source `https://ruby-doc.org/page` -- same web_source row is reused
3. `agent-tome source-search https://ruby-doc.org/page` -- returns both articles A and B

### 13.4 Keyword vocabulary discovery
1. Create articles with keywords `["ruby-gem", "ruby-thread", "rust", "python"]`
2. `agent-tome keywords rub` -- returns `["ruby-gem", "ruby-thread"]`
3. `agent-tome keywords ru` -- returns `["ruby-gem", "ruby-thread", "rust"]`

### 13.5 Cross-referencing articles (directional clarity)
1. Create article A
2. Create article B with `related_article_ids: [A's ID]` (B is source, A is target in the DB)
3. `agent-tome related A` -- `referenced_by` includes B, `references_to` is empty
4. `agent-tome related B` -- `references_to` includes A, `referenced_by` is empty
