# Agent Tome

Build a personal encyclopedia of accumulated knowledge, designed for AI agents.

Every research finding, technical discovery, and hard-won insight is captured and preserved in an append-only SQLite store — building your own encyclopedia over time. Designed for AI agents to read and write via Claude Code skills, so your agent remembers what you've already learned.

## Installation

```bash
gem install agent-tome
```

On first run, a config directory is created at `~/.agent-tome/` with a `config.yml` where you set `db_path` — the absolute path to your SQLite database file.

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

## Claude Code Skills

Agent Tome is designed to be used by AI agents via [Claude Code](https://claude.com/claude-code) skills:

- **[tome-lookup](https://github.com/beatmadsen/claude-skills/tree/main/skills/tome-lookup)** — Search the knowledge base before researching a topic
- **[tome-capture](https://github.com/beatmadsen/claude-skills/tree/main/skills/tome-capture)** — Save research findings to the knowledge base

Install them from the [claude-skills](https://github.com/beatmadsen/claude-skills) repository.

## Design Principles

- **Append-only**: No updates or deletions. Every piece of information is preserved.
- **Agent-first**: JSON in, JSON out. Simple commands with minimal flags.
- **Keyword-based discovery**: No full-text search — keywords are the only discovery mechanism, making consistent keyword usage critical.
- **Opaque identifiers**: All user-facing entities use randomly generated 7-character base58 global IDs.

## License

MIT
