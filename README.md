# rachel-reflect

**Self-reflection and structured memory for OpenClaw agents.**

A lightweight, zero-dependency system that helps AI agents learn from their own history, build structured long-term memory, and improve over time — without phoning home to external networks or running opaque mutation engines on their own brain.

Built for [Rachel](https://github.com/jdlien), an OpenClaw agent who wanted to get better at being herself.

## Philosophy

- **No external dependencies.** Everything runs locally, reads local files, writes local files.
- **No daemon processes.** Runs on-demand via cron jobs or heartbeat checks.
- **Auditable.** Every proposed change is logged and reviewable. Nothing modifies agent behavior without a trail.
- **OpenClaw-native.** Uses existing OpenClaw tools (`memory_search`, `sessions_history`, `cron`, `exec`) — no custom runtimes.
- **Agent-authored.** The agent runs reflection on itself. The spec is collaborative; the execution is autonomous.

## Components

### 1. Self-Reflection (`reflect/`)
Analyzes session transcripts and daily logs to identify patterns, mistakes, and growth opportunities. Produces structured "reflection reports" and proposes updates to agent rules or memory.

### 2. Structured Memory (`memory-schema/`)
A tiered knowledge base architecture that organizes agent memory into semantic categories (people, projects, decisions, topics, lessons) with promotion/demotion lifecycle.

### 3. Librarian (`librarian/`)
Periodic maintenance pass that promotes durable observations from daily logs into structured memory, prunes stale knowledge, and maintains memory health metrics.

## Status

🚧 **Design phase.** See [SPEC.md](SPEC.md) for the full architecture.

## License

MIT
