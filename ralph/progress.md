# Acceptance Test Progress

## 1. Configuration & Bootstrap
- [x] 1.1 First run creates config directory
- [x] 1.2 First run creates database and runs all migrations
- [x] 1.3 Pending migrations are applied automatically on invocation
- [x] 1.4 Migration state is tracked in the database
- [x] 1.5 Missing config file produces a clear error
- [x] 1.6 Missing db_path in config produces a clear error
- [x] 1.7 Unwritable db_path produces a clear error

## 2. `agent-tome create`
- [x] 2.1 Minimal article creation
- [x] 2.2 Article with all optional fields
- [x] 2.3 Keywords are singularised and downcased
- [x] 2.4 Keyword deduplication across articles
- [x] 2.5 Web source deduplication by normalised URL
- [x] 2.6 Web source URL normalisation preserves non-tracking query params
- [x] 2.7 File source deduplication by path and system_name
- [x] 2.8 File source with same path but different system_name creates new record
- [x] 2.9 Related article IDs create ArticleReference records
- [x] 2.10 Related article ID that does not exist is rejected
- [x] 2.22 Self-referencing related_article_ids is rejected
- [x] 2.11 Description exceeding 350 characters is rejected
- [x] 2.12 Missing description is rejected
- [x] 2.13 Missing body is rejected
- [x] 2.14 Blank/whitespace-only body is rejected
- [x] 2.15 Empty keyword string is rejected
- [x] 2.16 Invalid web source URL is rejected
- [x] 2.17 File source with empty path is rejected
- [x] 2.18 File source with empty system_name is rejected
- [x] 2.19 Description at exactly 350 characters is accepted
- [x] 2.20 Global IDs are 7-character base58 strings
- [x] 2.21 Internal IDs are never exposed in output

## 3. `agent-tome addend`
- [x] 3.1 Add content addendum to existing article
- [x] 3.2 Add keywords via addendum
- [x] 3.3 Metadata-only addendum (no body, just sources)
- [x] 3.4 Addendum with all fields
- [x] 3.5 Empty addendum is rejected
- [x] 3.6 Addendum with only empty body is rejected
- [x] 3.7 Addendum to non-existent article is rejected
- [x] 3.8 Duplicate keyword on addendum is idempotent
- [x] 3.9 Related article IDs on addendum

## 4. `agent-tome search`
- [x] 4.1 Search with default match mode (any)
- [x] 4.2 Search with --match all
- [x] 4.3 Search with --match any (explicit)
- [x] 4.4 Search results ordered by matching keyword count descending
- [x] 4.5 Search keywords are normalised before matching
- [x] 4.6 Search with no matching results
- [x] 4.7 Search results capped at 1000
- [x] 4.8 Search result format
- [x] 4.9 Search with no keywords

## 5. `agent-tome fetch`
- [x] 5.1 Fetch a simple article
- [x] 5.2 Fetch article with multiple entries
- [x] 5.3 Fetch article with sources on entries
- [x] 5.4 Fetch consolidated article includes consolidated_from
- [x] 5.5 Fetch non-existent article

## 6. `agent-tome consolidate`
- [x] 6.1 Basic consolidation
- [x] 6.2 Consolidation copies keywords
- [x] 6.3 Consolidation does not migrate ArticleReferences
- [x] 6.4 Consolidation with updated description
- [x] 6.5 Consolidation without description keeps original
- [x] 6.6 Consolidation requires body
- [x] 6.6b Consolidation rejects whitespace-only body
- [x] 6.6c Consolidation rejects description exceeding 350 characters
- [ ] 6.7 Fetching via original ID after consolidation returns new article
- [ ] 6.8 Fetching old article by its new ID still works
- [ ] 6.9 Consolidation of non-existent article

## 7. `agent-tome related`
- [ ] 7.1 Related via shared keywords
- [ ] 7.2 Related via shared keywords ordering
- [ ] 7.3 Related via ArticleReference (references_to)
- [ ] 7.3b Related via ArticleReference (referenced_by)
- [ ] 7.4 Related via ConsolidationLink (consolidated_from)
- [ ] 7.5 Related via ConsolidationLink (consolidated_into)
- [ ] 7.6 Article appears in multiple relation arrays
- [ ] 7.7 Empty results
- [ ] 7.8 Shared keywords capped at 100
- [ ] 7.9 Related for non-existent article

## 8. `agent-tome keywords`
- [ ] 8.1 Keywords matching a prefix
- [ ] 8.2 No matching keywords
- [ ] 8.3 Case-insensitive matching
- [ ] 8.4 No argument provided

## 9. `agent-tome source-search`
- [ ] 9.1 Search by URL
- [ ] 9.2 URL is normalised before matching
- [ ] 9.3 Search by file path (any system)
- [ ] 9.4 Search by file path with --system flag
- [ ] 9.5 No matching source
- [ ] 9.6 Output format
- [ ] 9.7 URL vs file path disambiguation

## 10. Output & Error Conventions
- [ ] 10.1 All commands output JSON to stdout
- [ ] 10.2 Success exit code is 0
- [ ] 10.3 Error exit code is non-zero
- [ ] 10.4 Errors are reported as structured JSON
- [ ] 10.5 Invalid JSON on stdin is rejected
- [ ] 10.7 Empty stdin is rejected
- [ ] 10.6 No command outputs internal integer IDs

## 11. Data Model Integrity
- [ ] 11.1 Global IDs are unique within each table
- [ ] 11.2 No records have updated_at
- [ ] 11.3 Duplicate keyword on same article is handled gracefully
- [ ] 11.4 Duplicate source link on same entry is prevented
- [ ] 11.5 Duplicate article reference is prevented

## 12. Namespace & Distribution
- [ ] 12.1 Gem provides agent-tome executable
- [ ] 12.2 Module namespace is Agent::Tome

## 13. End-to-End Workflows
- [ ] 13.1 Create, addend, search, fetch lifecycle
- [ ] 13.2 Create, consolidate, fetch lifecycle
- [ ] 13.3 Source deduplication across articles
- [ ] 13.4 Keyword vocabulary discovery
- [ ] 13.5 Cross-referencing articles (directional clarity)
