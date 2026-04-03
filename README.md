# Agent Tome

Build a personal encyclopedia of accumulated knowledge, designed for AI agents.

AI agents are brilliant researchers, and terrible at remembering what they found. Every new session starts from scratch: the same APIs re-discovered, the same docs re-read. Agent Tome gives your agent a place to store what it learns, so you can build the habits and tooling to stop repeating that work.

## Installation

```bash
gem install agent-tome
```

On first run, a config directory is created at `~/.agent-tome/` with a SQLite database at `~/.agent-tome/tome.db`. To use a different database location, edit `~/.agent-tome/config.yml` and change `db_path`.

## Quick Start

```bash
# Your agent just researched Ruby GC internals. Capture what it learned:
echo '{"description": "Ruby GC internals", "body": "Ruby uses a generational mark-and-sweep garbage collector.", "keywords": ["ruby", "garbage-collection"]}' | agent-tome create
# => {"global_id": "3xK9mWp", ...}

# Two weeks later, a different session hits the same topic.
# Instead of re-reading the docs, your agent checks the tome:
agent-tome search ruby gc

# The article exists. The agent adds what it learned today:
echo '{"body": "GC compaction was added in Ruby 2.7 via GC.compact."}' | agent-tome addend 3xK9mWp

# Fetch the full article with all entries
agent-tome fetch 3xK9mWp
```

## Knowledge Evolution

Articles grow over time as your agent adds findings from different sessions:

    Session 1: "Ruby uses mark-and-sweep GC"
    Session 3: "GC compaction added in Ruby 2.7"
    Session 7: "Tuning GC with RUBY_GC_HEAP_INIT_SLOTS"

Eventually, the article has redundant or overlapping entries. `consolidate` lets your agent (or you) synthesize them into a single authoritative entry:

    "Ruby uses generational mark-and-sweep GC with optional compaction
    (since 2.7). Key tuning env vars: RUBY_GC_HEAP_INIT_SLOTS, ..."

The original entries are preserved. The article ID still works. Keywords and sources are carried forward. This is how a tome stays useful over months instead of becoming a pile of notes.

## Commands

| Command | Description |
|---------|-------------|
| `agent-tome create` | Create a new article with its first entry (JSON via stdin) |
| `agent-tome addend <id>` | Add an addendum to an existing article (JSON via stdin) |
| `agent-tome search <keywords...>` | Search articles by keywords (`--match any` or `--match all`) |
| `agent-tome fetch <id>` | Retrieve full article content with all entries and sources |
| `agent-tome related <id>` | Find articles related through shared keywords or references |
| `agent-tome consolidate <id>` | Merge all addenda into a single consolidated article (JSON via stdin) |
| `agent-tome keywords <prefix>` | List keywords matching a prefix for vocabulary discovery |
| `agent-tome source-search <url-or-path>` | Find articles referencing a given source |

## Agent Integration

Agent Tome works with any tool that can call a CLI. JSON in, JSON out, exit code 0 on success:

- **Claude Code**: Use the companion [tome-lookup](https://github.com/beatmadsen/claude-skills/tree/main/skills/tome-lookup) and [tome-capture](https://github.com/beatmadsen/claude-skills/tree/main/skills/tome-capture) skills from the [claude-skills](https://github.com/beatmadsen/claude-skills) repository
- **Cursor / Windsurf**: Call `agent-tome` as a custom tool or shell command
- **MCP servers**: Wrap the CLI as a tool definition
- **Any agent framework**: If it can `exec` a process and read stdout, it works

No SDK, no API keys, no server. The CLI is the interface.

## Design Principles

- **Append-only**: Your agent can never corrupt or lose knowledge. There are no updates or deletions. When information evolves, `consolidate` synthesizes a clean entry while keeping the full history.
- **Agent-first**: JSON in, JSON out. Simple commands with minimal flags. Every response is machine-parseable, every error is structured.
- **Keyword-based discovery**: Retrieval is deterministic. You always know exactly why a result came back and what keywords will find it again. No embeddings to configure, no similarity thresholds to tune.
- **Opaque identifiers**: All user-facing entities use randomly generated 7-character base58 global IDs. Internal details never leak into your agent's context.

## License

MIT
