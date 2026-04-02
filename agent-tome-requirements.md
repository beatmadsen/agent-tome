# Agent-Tome — Personal Knowledge Base

## Overview

Tome is a Ruby gem providing a CLI tool for building and querying a personal knowledge base. It is designed primarily for consumption by AI agents (via a Claude skill), though it is also usable by humans. The knowledge base stores research findings, reports, and accumulated knowledge in an append-only, immutable data model backed by SQLite.

The gem is installed via `gem install agent-tome` and provides an `agent-tome` executable.

---

## Design Principles

- **Append-only / Immutable**: No updates or deletions. Every piece of information is preserved. Records carry only a `created_at` timestamp — no `updated_at`.
- **Agent-first**: All output is JSON. All complex input is JSON via stdin. The CLI surface is simple commands with minimal flags.
- **Normalised data model**: Foreign keys, constraints, and deduplication where appropriate.
- **Opaque identifiers**: Primary keys are never exposed. All user-facing entities use randomly generated 7-character base58 global IDs. Collisions fail hard (unique constraint violation) and the caller retries.
- **Information preservation**: Validation prevents bad data at the boundary. No delete operations are exposed. Manual database access is the escape hatch for worst-case cleanup.

---

## Configuration

A configuration file is stored at `~/.agent-tome/config.yml`. At minimum it holds:

- `db_path`: Absolute path to the SQLite database file. The user is responsible for placing this in a cloud-synced directory (OneDrive, etc.).

The config directory (`~/.agent-tome/`) is created automatically on first run. Migration state is tracked inside the SQLite database itself (via ActiveRecord's `schema_migrations` table), not in the config directory.

---

## Data Model

The `Agent::Tome` module defines `self.table_name_prefix` as `''` to prevent ActiveRecord from prefixing all table names with `agent_tome_`. Table names follow ActiveRecord's default pluralisation.

### Article (table: `articles`)

The top-level knowledge container. Does not hold content directly.

| Column | Type | Notes |
|---|---|---|
| id | integer | PK, internal only, never exposed |
| global_id | string(7) | Base58, unique, indexed |
| description | text | Max 350 characters. A two-line summary expressing the nature of the article for filtering/triage purposes |
| created_at | datetime | |

### Entry (table: `entries`)

A unit of content within an article. The first entry is created alongside the article. Subsequent entries are addenda.

| Column | Type | Notes |
|---|---|---|
| id | integer | PK, internal only, never exposed |
| global_id | string(7) | Base58, unique, indexed |
| article_id | integer | FK → articles, not null |
| body | text | The content. May be null for metadata-only addenda (adding keywords/sources without new content) |
| created_at | datetime | |

### Keyword (table: `keywords`)

Stored in singularised form (via `ActiveSupport::Inflector.singularize`), downcased. Deduplicated — the same keyword string is never stored twice. Singularisation applies to the last word only, following ActiveSupport's default behaviour (e.g., `"concurrent-processes"` → `"concurrent-process"`, `"web-sources"` → `"web-source"`). Multi-word and hyphenated keywords are treated as single tokens.

| Column | Type | Notes |
|---|---|---|
| id | integer | PK, internal only |
| term | string | Unique, indexed, singularised, downcased |
| created_at | datetime | |

### ArticleKeyword (table: `article_keywords`, join table)

| Column | Type | Notes |
|---|---|---|
| id | integer | PK |
| article_id | integer | FK → articles, not null |
| keyword_id | integer | FK → keywords, not null |
| created_at | datetime | |

Unique constraint on `(article_id, keyword_id)`.

### WebSource (table: `web_sources`)

Deduplicated by normalised URL. Normalisation strips known tracking parameters (`utm_*`, `fbclid`, etc.) but preserves all other query parameters, as they are often semantically significant.

| Column | Type | Notes |
|---|---|---|
| id | integer | PK, internal only |
| global_id | string(7) | Base58, unique, indexed |
| url | text | Normalised URL, unique, indexed |
| title | string | Optional, human-readable label |
| fetched_at | datetime | Optional, when the content was retrieved — allows agents to infer current relevance |
| created_at | datetime | |

### FileSource (table: `file_sources`)

Deduplicated by `(path, system_name)`.

| Column | Type | Notes |
|---|---|---|
| id | integer | PK, internal only |
| global_id | string(7) | Base58, unique, indexed |
| path | text | Absolute file path |
| system_name | string | Identifier for the computer/system where the path is valid |
| created_at | datetime | |

Unique constraint on `(path, system_name)`.

### EntryWebSource (table: `entry_web_sources`, join table)

| Column | Type | Notes |
|---|---|---|
| id | integer | PK |
| entry_id | integer | FK → entries, not null |
| web_source_id | integer | FK → web_sources, not null |
| created_at | datetime | |

Unique constraint on `(entry_id, web_source_id)`.

### EntryFileSource (table: `entry_file_sources`, join table)

| Column | Type | Notes |
|---|---|---|
| id | integer | PK |
| entry_id | integer | FK → entries, not null |
| file_source_id | integer | FK → file_sources, not null |
| created_at | datetime | |

Unique constraint on `(entry_id, file_source_id)`.

### ArticleReference (table: `article_references`)

Generic "relates to" link between two articles. No typed relationships — just an association.

| Column | Type | Notes |
|---|---|---|
| id | integer | PK |
| source_article_id | integer | FK → articles, not null |
| target_article_id | integer | FK → articles, not null |
| created_at | datetime | |

Unique constraint on `(source_article_id, target_article_id)`.

### ConsolidationLink (table: `consolidation_links`)

Records that one article was consolidated from another. Separate table from ArticleReference to distinguish the semantics at the schema level.

| Column | Type | Notes |
|---|---|---|
| id | integer | PK |
| new_article_id | integer | FK → articles, not null |
| old_article_id | integer | FK → articles, not null |
| created_at | datetime | |

---

## CLI Commands

All commands output JSON to stdout. Commands that accept complex input receive it as JSON via stdin. Exit codes follow convention: 0 for success, non-zero for errors. Errors are also reported as JSON.

### `agent-tome create`

Creates a new article with its first entry.

**Input** (JSON via stdin):

```json
{
  "description": "Brief summary of the article, max 350 chars",
  "body": "The content of the first entry",
  "keywords": ["keyword1", "keyword2"],
  "web_sources": [
    { "url": "https://example.com/page", "title": "Optional title", "fetched_at": "2025-06-01T12:00:00Z" }
  ],
  "file_sources": [
    { "path": "/home/user/doc.pdf", "system_name": "work-laptop" }
  ],
  "related_article_ids": ["Ab3xK9m"]
}
```

All fields except `description` and `body` are optional. Keywords are singularised and downcased before storage. Sources are deduplicated — if a web source with the same normalised URL already exists, the existing record is reused. Same for file sources by `(path, system_name)`.

**Output**: The created article's global ID, the entry's global ID, and any source global IDs.

### `agent-tome addend <article_global_id>`

Adds an addendum to an existing article. Can add content, keywords, sources, or any combination.

**Input** (JSON via stdin):

```json
{
  "body": "Additional content (optional — omit for metadata-only addendum)",
  "keywords": ["new-keyword"],
  "web_sources": [],
  "file_sources": [],
  "related_article_ids": ["Zp4wQ2r"]
}
```

At least one field must be substantively present: `body` must be a non-empty string, or at least one of `keywords`, `web_sources`, `file_sources`, or `related_article_ids` must be a non-empty array. An input where all arrays are empty and `body` is omitted is rejected. If `body` is omitted or null, an entry is still created (to anchor any new sources), but its body is null. Keywords are added to the article. Sources are attached to the new entry.

**Output**: The new entry's global ID, any new source global IDs.

### `agent-tome search <keywords...>`

Searches for articles matching the given keywords.

**Flags**:
- `--match all` — articles must have every specified keyword (AND). 
- `--match any` — articles must have at least one specified keyword (OR). Default.

Keywords provided by the caller are singularised and downcased before matching, using the same normalisation as storage.

**Output**: Up to 1000 results, ordered by number of matching keywords descending. Each result includes:

```json
{
  "results": [
    {
      "global_id": "Ab3xK9m",
      "description": "...",
      "keywords": ["matching", "keyword", "list"],
      "matching_keyword_count": 2,
      "created_at": "2025-06-01T12:00:00Z"
    }
  ]
}
```

### `agent-tome fetch <article_global_id>`

Retrieves the full content of an article.

**Output**:

```json
{
  "global_id": "Ab3xK9m",
  "description": "...",
  "keywords": ["keyword1", "keyword2"],
  "created_at": "2025-06-01T12:00:00Z",
  "consolidated_from": {
    "global_id": "Xr9pL2w",
    "description": "..."
  },
  "entries": [
    {
      "global_id": "Qw8mN3k",
      "body": "Content of this entry",
      "created_at": "2025-06-01T12:00:00Z",
      "web_sources": [
        { "global_id": "Yt5vB1x", "url": "https://...", "title": "...", "fetched_at": "..." }
      ],
      "file_sources": [
        { "global_id": "Mn2kP8r", "path": "/home/...", "system_name": "work-laptop" }
      ]
    }
  ]
}
```

Entries are ordered chronologically. The `consolidated_from` field is present only if this article was created via consolidation, and includes the global ID and description of the previous article.

### `agent-tome consolidate <article_global_id>`

Merges all addenda of an article into a single new consolidated article.

The purpose of the ID swap is continuity: any agent or skill that has cached the article's global ID will get the improved, consolidated content on next fetch. The previous version remains accessible under a new ID via the consolidation link.

**Process**:
1. The new article takes over the original article's global ID.
2. The original article is assigned a new global ID.
3. A ConsolidationLink is created from the new article to the old article.
4. All keywords from the original article are copied to the new article.
5. All sources (web and file) from the original article's entries are copied to the new article's consolidated entry. This preserves provenance — the consolidated content is derived from the same information.
6. All ArticleReferences involving the original article are **not** migrated — they remain pointing at the original (now re-IDed) article. The consolidation link provides the connection.

**Input** (JSON via stdin):

```json
{
  "body": "The merged/rewritten content",
  "description": "Updated description (optional — keeps original if omitted)"
}
```

`body` is required. The agent is responsible for producing the merged content.

**Output**: The global IDs of the new and old articles.

### `agent-tome related <article_global_id>`

Finds articles related to the given article through shared keywords or explicit references (ArticleReference and ConsolidationLink).

**Output**: Separate arrays grouped by relation type. An article may appear in multiple arrays if related through multiple paths.

```json
{
  "shared_keywords": [
    { "global_id": "...", "description": "...", "keywords": [...], "shared_keyword_count": 3, "created_at": "..." }
  ],
  "references_to": [
    { "global_id": "...", "description": "...", "keywords": [...], "created_at": "..." }
  ],
  "referenced_by": [
    { "global_id": "...", "description": "...", "keywords": [...], "created_at": "..." }
  ],
  "consolidated_from": [
    { "global_id": "...", "description": "...", "keywords": [...], "created_at": "..." }
  ],
  "consolidated_into": [
    { "global_id": "...", "description": "...", "keywords": [...], "created_at": "..." }
  ]
}
```

`shared_keywords` results are ordered by shared keyword count descending, limited to the top 100. Empty arrays are included for consistency.

### `agent-tome keywords <prefix>`

Lists keywords matching a prefix/substring. Lightweight output for vocabulary discovery.

**Input**: A positional argument — the prefix string.

**Output**:

```json
{
  "keywords": ["concurrency", "concurrent-process"]
}
```

### `agent-tome source-search <url-or-path>`

Finds articles that reference a given source.

**Input**: A positional argument — a URL or file path. URLs are normalised before matching. File paths match on the path component across all systems by default.

**Flags**:
- `--system <name>` — restrict file path matching to the specified system name.

**Output**: Array of matching articles. Each result includes `global_id`, `description`, `keywords`, and `created_at`. (No `matching_keyword_count` — source-search does not match on keywords.)

---

## Technology Stack

- **Language**: Ruby
- **Database**: SQLite (single file, user-managed backup via cloud sync)
- **ORM**: ActiveRecord (standalone, without Rails)
- **Migrations**: ActiveRecord migrations, shipped inside the gem under `db/migrate`, tracked via the `schema_migrations` table in the SQLite database.
- **Singularisation**: `ActiveSupport::Inflector.singularize`
- **Distribution**: RubyGems (`gem install agent-tome`)
- **Namespace**: `Agent::Tome` — follows RubyGems dash convention (`agent-tome` → `Agent::Tome`). Part of the `Agent::*` family alongside `agent-chat`. Entry point: `require 'agent/tome'`. Directory structure: `lib/agent/tome.rb`.
- **ID generation**: Random 7-character base58 strings. Uniqueness enforced by database constraint — collisions cause a hard failure and the caller retries.

---

## Migration Strategy

Migration files are shipped inside the gem. On every CLI invocation, before executing any command, agent-tome checks for pending migrations and applies them automatically. This is transparent to the caller — agents never need to run a separate migration command.

**How it works**: ActiveRecord's `schema_migrations` table records which migrations have been applied. On each invocation, agent-tome compares the migration files in the gem against the versions in `schema_migrations` and runs any that are pending. The check is a single `SELECT` against a tiny table plus a directory listing — negligible overhead on top of the ActiveRecord/ActiveSupport boot cost that every command already incurs.

**Scenarios**:

- **First run**: The database file does not exist. Agent-tome creates it at the configured path, runs all migrations, and proceeds with the command.
- **Gem upgrade**: New gem version ships new migration files. They are applied automatically on the next invocation.
- **Gem downgrade**: Not supported. Rolling back migrations risks data loss, which is unacceptable given the append-only design. Downgrading the gem while keeping a database migrated to a newer version may result in errors if the code references tables or columns that don't exist yet. This is acceptable — users should not downgrade.
- **Shared database across systems**: If the SQLite file is synced via cloud storage and accessed by different machines running different gem versions, the first machine to upgrade will migrate the database. Older gem versions on other machines may encounter unknown tables or columns. SQLite is lenient here (queries only fail if they reference missing columns), but users should keep gem versions in sync across machines.

---

## Input Validation

All JSON input is validated against a defined schema before any database operations. Validation includes:

- `description` must be present and ≤ 350 characters.
- `body` must be a non-empty string when provided (not blank/whitespace-only).
- Keywords must be non-empty strings.
- Web source URLs must be valid URLs.
- File source paths must be non-empty, `system_name` must be non-empty.
- Referenced article global IDs (for `related_article_ids`) must exist.

Validation errors are returned as structured JSON with clear error messages.

---

## Non-Requirements

- No update or delete operations are exposed via the CLI.
- No user authentication or multi-tenancy — single-user system.
- No full-text search (keyword-based search only).
- No automatic keyword extraction — the caller supplies keywords.
- No file content storage — only paths and metadata.
- No Rails dependency.
