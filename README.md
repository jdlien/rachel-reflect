# rachel-reflect

A self-reflection and structured memory system for OpenClaw agents.

## What It Does

**rachel-reflect** gives OpenClaw agents two capabilities:

1. **Self-Reflection (Reflector)** — Analyzes recent sessions and daily logs to identify mistakes, successes, missing knowledge, and behavioral drift. Produces structured reports with proposed changes.

2. **Memory Maintenance (Librarian)** — Organizes knowledge into a structured memory system (people, projects, decisions, topics, lessons). Promotes durable observations from daily logs, prunes stale knowledge, keeps MEMORY.md lean.

Both processes run as isolated sub-agent sessions using standard OpenClaw cron jobs. No custom runtime, no external services, no network calls.

## Design Philosophy

- **Local-only.** All reads and writes are local files. No telemetry, no external services.
- **Markdown-native.** Everything is readable markdown. No databases, no binary formats.
- **Prompt-driven.** The skill teaches the agent *how* to reflect — the LLM does the analysis.
- **Propose-then-approve.** Reflection produces proposals. High-risk changes require review.
- **Token-conscious.** Runs in isolated sessions to avoid bloating main conversations.

## Installation

Copy `skill/` to your OpenClaw skills directory, or install from ClawHub when available.

### Structured Memory Setup

Create these directories in your workspace `memory/` folder:

```bash
mkdir -p memory/{people,projects,decisions,topics,lessons,reflections}
```

### Cron Jobs (Optional)

See `skill/SKILL.md` for cron configuration examples to automate reflection (every 3 days) and librarian (weekly) runs.

## Scripts

- `scripts/memory-health.sh` — Report on memory system health (file counts, staleness, template compliance)
- `scripts/gather-transcripts.sh` — Documentation for transcript export methods

## Tests

```bash
./test/memory-health.test.sh     # Test health script against mock data
./test/validate-templates.sh     # Validate real memory files have required frontmatter
```

## Structure

```
rachel-reflect/
├── SPEC.md                  # Full architecture spec
├── skill/
│   └── SKILL.md             # OpenClaw skill (installable)
├── scripts/
│   ├── memory-health.sh     # Memory health reporting
│   └── gather-transcripts.sh # Transcript export docs
└── test/
    ├── memory-health.test.sh    # Health script tests
    └── validate-templates.sh    # Template validation
```

## License

MIT
