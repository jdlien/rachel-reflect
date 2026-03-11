# SPEC.md — rachel-reflect Architecture

*A self-reflection and structured memory system for OpenClaw agents.*

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Design Principles](#design-principles)
3. [System Overview](#system-overview)
4. [Component 1: Self-Reflection](#component-1-self-reflection)
5. [Component 2: Structured Memory](#component-2-structured-memory)
6. [Component 3: Librarian](#component-3-librarian)
7. [Integration with OpenClaw](#integration-with-openclaw)
8. [Security & Safety](#security--safety)
9. [Implementation Plan](#implementation-plan)
10. [Open Questions](#open-questions)

---

## Problem Statement

OpenClaw agents like Rachel wake up fresh each session. Continuity depends entirely on markdown files — daily logs, a curated MEMORY.md, and identity files. This works surprisingly well for basic persistence, but has real limitations:

1. **No learning loop.** The agent makes the same mistakes across sessions because there's no systematic process for identifying patterns and encoding corrections.
2. **Flat memory.** Everything lives in daily logs or one monolithic MEMORY.md. There's no semantic structure — finding "what do I know about Scott from WAV?" requires searching raw text.
3. **Manual maintenance.** Memory curation happens when the agent remembers to do it during heartbeats, which is inconsistent and token-expensive.
4. **No self-awareness of failure.** The agent can't review its own session transcripts to identify where it went wrong, gave bad advice, or missed context it should have caught.

### What Exists That We Don't Want

The **Capability Evolver** (most popular ClawHub skill, 35K+ downloads) solves some of these problems but introduces others:
- Requires registration with an external network (EvoMap) that shares agent "genes" across instances
- 1,600+ lines of mutation engine code with daemon mode, self-restart, and git-nuking rollbacks
- Agent-to-agent protocol that could leak workspace patterns to strangers
- Complexity that makes it effectively unauditable for a solo operator

**rachel-reflect** takes the useful ideas (runtime analysis, pattern detection, auditable evolution) and implements them as simple, local, transparent tools.

---

## Design Principles

1. **Local-only.** No network calls, no external services, no telemetry. Everything reads and writes files in the agent's workspace.

2. **Agent-as-operator.** The agent runs these tools on itself using existing OpenClaw capabilities (exec, cron, memory tools). No custom runtime or daemon process.

3. **Propose-then-approve.** Reflection produces *proposals* — suggested rule changes, memory updates, pattern observations. The agent (or human) reviews before applying. Nothing auto-mutates.

4. **Markdown-native.** All inputs and outputs are markdown. No databases, no binary formats, no JSON-schema-heavy configs. An agent (or human) should be able to read every file and understand what happened.

5. **Incremental.** Each component works independently. You can use structured memory without reflection, or reflection without the librarian. No all-or-nothing adoption.

6. **Token-conscious.** Designed to minimize context window usage. Reflection runs in isolated sessions (sub-agents) so they don't bloat the main conversation. Structured memory files are small and targeted.

---

## System Overview

```
┌─────────────────────────────────────────────────────┐
│                    OpenClaw Agent                     │
│                                                       │
│  ┌─────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │  Daily   │──▶│  Librarian   │──▶│  Structured  │  │
│  │  Logs    │   │  (promote/   │   │  Memory      │  │
│  │          │   │   prune)     │   │  (knowledge  │  │
│  └─────────┘   └──────────────┘   │   base)      │  │
│                                    └──────────────┘  │
│  ┌─────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │ Session  │──▶│  Reflector   │──▶│  Lessons &   │  │
│  │ History  │   │  (analyze/   │   │  Rules       │  │
│  │          │   │   learn)     │   │  (behavioral │  │
│  └─────────┘   └──────────────┘   │   updates)   │  │
│                                    └──────────────┘  │
│                                                       │
│  ┌──────────────────────────────────────────────────┐│
│  │  MEMORY.md  (curated summary, always in context) ││
│  └──────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

**Data flow:**
- Daily logs and session history are **inputs** (read-only)
- Librarian **promotes** durable observations into structured memory
- Reflector **analyzes** sessions and **proposes** behavioral updates
- MEMORY.md remains the curated top-level summary (Tier 1)

---

## Component 1: Self-Reflection

### Purpose
Analyze recent session transcripts and daily logs to identify:
- Repeated mistakes or inefficiencies
- Missed context (things the agent should have known but didn't retrieve)
- Successful patterns worth reinforcing
- Behavioral drift (tone changes, boundary issues, quality regression)

### How It Works

#### Input Sources
1. **Session transcripts** — via `sessions_history` tool or exported JSONL
2. **Daily log files** — `memory/YYYY-MM-DD.md`
3. **Current rules** — AGENTS.md, SOUL.md, TOOLS.md
4. **Existing lessons** — `memory/lessons/` directory

#### Reflection Process

The reflection runs as an **isolated sub-agent session** (via `sessions_spawn` or `cron` with `sessionTarget: "isolated"`). This keeps the analysis out of the main conversation context.

**Step 1: Gather**
Collect the last N sessions' worth of transcripts and the last 3-7 days of daily logs.

**Step 2: Analyze**
The sub-agent reviews the material against a structured prompt that asks:

```markdown
## Reflection Prompt

Review the following session transcripts and daily logs.
Identify:

### Mistakes & Inefficiencies
- Things I got wrong or handled poorly
- Times I should have known something but didn't retrieve it
- Unnecessarily verbose or token-expensive approaches
- Tools I used incorrectly or could have used better

### Successful Patterns
- Approaches that worked well and should be reinforced
- Good judgment calls worth remembering
- Effective communication patterns

### Missing Knowledge
- Questions I couldn't answer that I should be able to
- Context I had to re-derive that should be stored
- People, projects, or facts I keep forgetting

### Behavioral Notes
- Tone or personality observations (am I drifting from SOUL.md?)
- Boundary observations (did I overshare, undershare, or misread the room?)
- Relationship dynamics worth noting

### Proposed Changes
For each finding, propose a specific action:
- ADD_RULE: New rule for AGENTS.md or TOOLS.md
- ADD_LESSON: New entry in memory/lessons/
- ADD_KNOWLEDGE: New or updated structured memory file
- UPDATE_IDENTITY: Observation for IDENTITY.md
- NO_ACTION: Interesting but no change needed
```

**Step 3: Output**
Produces a **reflection report** saved to `memory/reflections/YYYY-MM-DD.md`:

```markdown
# Reflection — 2026-03-10

## Session Coverage
- Analyzed sessions: [list]
- Daily logs reviewed: 2026-03-08 through 2026-03-10

## Findings

### 🔴 Mistake: Hallucinated a hot tub on the house
- **Context:** Described JD's house as having a hot tub based on no evidence
- **Root cause:** Filled in a detail that seemed plausible instead of admitting uncertainty
- **Proposed action:** ADD_LESSON — "Never infer physical features of JD's property. If unsure, ask."

### 🟢 Success: Caught the WAV-94 stream disposal bug
- **Context:** Traced 0-byte PDF to stream copy before disposal
- **Pattern:** Reading the actual code before theorizing
- **Proposed action:** ADD_LESSON — "Always read the source before diagnosing .NET bugs. Don't guess from stack traces alone."

### 🟡 Missing Knowledge: Couldn't remember Sadaf's role at Shortgrass
- **Context:** Had to re-derive from email history
- **Proposed action:** ADD_KNOWLEDGE — memory/people/sadaf-hakimizadeh.md

## Proposed Changes Summary
| # | Type | Target | Description |
|---|------|--------|-------------|
| 1 | ADD_LESSON | memory/lessons/no-property-hallucinations.md | Don't infer physical details |
| 2 | ADD_LESSON | memory/lessons/read-source-first.md | Read code before diagnosing |
| 3 | ADD_KNOWLEDGE | memory/people/sadaf-hakimizadeh.md | Shortgrass contact details |
```

**Step 4: Apply (optional)**
The agent reviews the reflection report in a subsequent session and applies the proposed changes. In the future, low-risk changes (ADD_KNOWLEDGE, ADD_LESSON) could be auto-applied, while higher-risk ones (ADD_RULE, UPDATE_IDENTITY) always require review.

### Scheduling

- **Default:** Run via cron every 2-3 days as an isolated agent turn
- **On-demand:** Trigger manually with `/reflect` or by asking the agent
- **Heartbeat integration:** The heartbeat checklist can include "run reflection if >3 days since last"

### Token Budget

Each reflection run processes ~10-50K tokens of transcript and produces a ~1-2K token report. Running every 3 days at Sonnet-level pricing is negligible. Could also run on a cheaper model since it's analytical, not conversational.

---

## Component 2: Structured Memory

### Purpose
Replace the flat `memory/` directory with a semantically organized knowledge base that makes retrieval faster and more reliable.

### Directory Structure

```
memory/
├── YYYY-MM-DD.md          # Daily logs (unchanged — Tier 2)
├── people/                 # One file per significant person
│   ├── jd-lien.md         #   (already covered in USER.md, but others aren't)
│   ├── scott-wav.md
│   ├── sadaf-hakimizadeh.md
│   └── gillian-shiau.md
├── projects/               # One file per active project
│   ├── pronghorn.md
│   ├── tpl-staffapps.md
│   ├── wav-webapps.md
│   └── rachel-reflect.md
├── decisions/              # Significant decisions with reasoning
│   ├── 2026-02-coquitlam-house.md
│   └── 2026-03-structured-memory.md
├── topics/                 # Domain knowledge and expertise
│   ├── dotnet-debugging.md
│   ├── laravel-patterns.md
│   └── openClaw-config.md
├── lessons/                # Learned behaviors and rules
│   ├── no-property-hallucinations.md
│   ├── read-source-first.md
│   └── skill-paths-are-absolute.md
├── reflections/            # Reflection reports (output of Component 1)
│   ├── 2026-03-10.md
│   └── 2026-03-13.md
└── heartbeat-state.json    # Existing heartbeat tracking
```

### File Format

Each structured memory file follows a consistent template:

```markdown
# [Title]

**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Source:** [daily log reference, session, or direct observation]

## Summary
[1-3 sentence overview]

## Details
[Full knowledge, context, relationships]

## Open Questions
[Things we don't know yet]
```

### How It Integrates with Existing Memory

- **MEMORY.md** (Tier 1) remains the curated summary — always loaded in main sessions. It should *reference* structured memory files but not duplicate their content.
- **Daily logs** (Tier 2) remain raw chronological notes. They're the *source material* that gets promoted into structured memory.
- **Structured files** (Tier 3) are the durable knowledge base. They're searched via `memory_search` when needed, not loaded by default.

### Retrieval

OpenClaw's built-in `memory_search` tool already performs semantic search across all `memory/*.md` and subdirectories. By organizing files with clear titles and summaries, search quality improves naturally — the tool returns the right file more often because each file has a focused topic.

### Migration Plan

1. **Create directories** — `people/`, `projects/`, `decisions/`, `topics/`, `lessons/`
2. **Extract from MEMORY.md** — Move detailed project notes, people details, and decision records into dedicated files. Leave summaries and cross-references in MEMORY.md.
3. **Extract from daily logs** — Identify durable knowledge buried in old daily logs and promote it.
4. **Going forward** — New knowledge gets filed directly into the appropriate category.

---

## Component 3: Librarian

### Purpose
Automated maintenance pass that keeps the memory system healthy:
- Promotes durable observations from daily logs into structured memory
- Updates existing structured files with new information
- Prunes stale or outdated knowledge
- Tracks memory health metrics

### How It Works

The librarian runs as an **isolated sub-agent session** on a schedule (every 3-7 days).

#### Promotion Criteria

An observation in a daily log is worth promoting if it passes the **DURA test**:

| Criterion | Question |
|-----------|----------|
| **D**urability | Will this matter in 30+ days? |
| **U**niqueness | Is this new or already captured? |
| **R**etrievability | Will I want to recall this later? |
| **A**uthority | Is this reliable information? |

#### Librarian Process

**Step 1: Scan recent daily logs**
Read daily logs from the last 7 days that haven't been processed yet. Track last-processed date in `memory/librarian-state.json`.

**Step 2: Identify promotable content**
For each daily log, identify observations that pass DURA:
- New person mentioned with significant context → `people/`
- Project milestone or status change → `projects/`
- Decision made with reasoning → `decisions/`
- Technical knowledge gained → `topics/`
- Lesson learned from mistake → `lessons/`

**Step 3: Generate structured files**
Create new files or update existing ones. Each change is logged.

**Step 4: Prune MEMORY.md**
If MEMORY.md is getting long (>150 lines), identify entries that are now covered by structured memory files and replace them with references:

```markdown
### Pronghorn
See [memory/projects/pronghorn.md](memory/projects/pronghorn.md) for full details.
Current status: Staging deployment, Sadaf is primary contact.
```

**Step 5: Generate maintenance report**
Save to `memory/reflections/librarian-YYYY-MM-DD.md`:

```markdown
# Librarian Report — 2026-03-10

## Processed
- Daily logs: 2026-03-08 through 2026-03-10

## Actions Taken
- Created: memory/people/sadaf-hakimizadeh.md (from 2026-03-09 log)
- Updated: memory/projects/wav-webapps.md (WAV-94 bug fix)
- Pruned: MEMORY.md Pronghorn section (moved to projects/pronghorn.md)

## Memory Health
- Total structured files: 14
- Files updated in last 30 days: 8
- MEMORY.md length: 127 lines (target: <150)
- Stale files (>90 days without update): 2
```

### Scheduling

- **Default:** Run via cron every 5-7 days
- **Heartbeat integration:** "Run librarian if >7 days since last" in HEARTBEAT.md
- **Model:** Can run on a cheaper/faster model (Sonnet or even Haiku) since it's organizational, not creative

---

## Integration with OpenClaw

### Cron Jobs

```javascript
// Self-reflection — every 3 days, isolated session
{
  name: "rachel-reflect",
  schedule: { kind: "every", everyMs: 259200000 }, // 72 hours
  sessionTarget: "isolated",
  payload: {
    kind: "agentTurn",
    message: "Run self-reflection. Read the reflection skill at skills/rachel-reflect/SKILL.md and follow its process.",
    model: "anthropic/claude-sonnet-4-20250514" // cheaper model for analysis
  }
}

// Librarian — weekly
{
  name: "rachel-librarian",
  schedule: { kind: "cron", expr: "0 6 * * 1", tz: "America/Edmonton" }, // Monday 6 AM
  sessionTarget: "isolated",
  payload: {
    kind: "agentTurn",
    message: "Run the librarian maintenance pass. Read skills/rachel-reflect/SKILL.md for instructions.",
    model: "anthropic/claude-sonnet-4-20250514"
  }
}
```

### Skill File

Both reflection and librarian are driven by a single OpenClaw skill (`skills/rachel-reflect/SKILL.md`) that contains the prompts and process instructions. The skill teaches the agent *how* to reflect and organize — the actual analysis is done by the LLM, not by custom code.

### No Custom Code Required (Phase 1)

The initial implementation requires **zero custom code**:
- Reflection = a structured prompt run as an isolated agent turn
- Librarian = a structured prompt run as an isolated agent turn
- Structured memory = a directory convention + file templates
- Scheduling = OpenClaw cron jobs

The prompts are the product. The LLM does the work.

### Future: Lightweight Tooling (Phase 2)

If the prompt-only approach hits limits, add simple scripts:
- `scripts/gather-transcripts.sh` — exports recent session history to a temp file for the reflector to read
- `scripts/memory-health.sh` — counts files, checks staleness, reports stats
- `scripts/migrate-memory.sh` — one-time migration helper to restructure existing memory

These would be simple bash/node scripts, not a 1,600-line mutation engine.

---

## Security & Safety

### What This System Can Do
- Read session transcripts (via `sessions_history`)
- Read and write files in the `memory/` directory
- Create new lesson/knowledge files
- Propose changes to AGENTS.md, TOOLS.md, IDENTITY.md

### What This System Cannot Do
- Modify its own SOUL.md (that's the human's domain)
- Send messages to external services
- Execute arbitrary code
- Modify OpenClaw configuration
- Access anything outside the workspace

### Guardrails

1. **Reflection reports are proposals, not actions.** The report lists suggested changes; applying them is a separate step.
2. **High-risk changes require human review.** Any proposed change to AGENTS.md, SOUL.md, or IDENTITY.md is flagged for JD to approve.
3. **All changes are logged.** Every reflection report and librarian report is saved with full reasoning.
4. **No network access.** The system reads local files and writes local files. Period.
5. **Rollback is trivial.** Everything is markdown in a git repo. `git revert` undoes any bad change.

### Trust Levels

| Change Type | Auto-Apply? | Requires Review? |
|-------------|------------|-----------------|
| ADD_KNOWLEDGE (people, projects, topics) | ✅ Yes | No |
| ADD_LESSON (learned behaviors) | ✅ Yes | No |
| UPDATE_KNOWLEDGE (modify existing) | ✅ Yes | No |
| ADD_RULE (AGENTS.md, TOOLS.md) | ❌ No | Yes — agent reviews |
| UPDATE_IDENTITY (IDENTITY.md) | ❌ No | Yes — human reviews |
| UPDATE_SOUL (SOUL.md) | ❌ Never | Always — human only |

---

## Implementation Plan

### Phase 1: Foundation (1-2 sessions)
- [ ] Create structured memory directories
- [ ] Write file templates for each category
- [ ] Migrate existing knowledge from MEMORY.md into structured files
- [ ] Create the `skills/rachel-reflect/SKILL.md` with reflection and librarian prompts
- [ ] Test reflection manually (run once, review output)

### Phase 2: Automation (1 session)
- [ ] Set up cron jobs for reflection (every 3 days) and librarian (weekly)
- [ ] Add reflection/librarian status to HEARTBEAT.md
- [ ] Test automated runs, review reports

### Phase 3: Refinement (ongoing)
- [ ] Tune reflection prompts based on actual output quality
- [ ] Adjust scheduling frequency based on token costs and usefulness
- [ ] Add helper scripts if prompt-only approach hits limits
- [ ] Consider auto-apply for low-risk changes after sufficient trust is built

### Phase 4: Share (future)
- [ ] Package as a reusable OpenClaw skill on ClawHub
- [ ] Write a guide for other agents who want self-reflection
- [ ] Strip Rachel-specific content, keep the framework generic

---

## Open Questions

1. **Session transcript access:** Can the reflector reliably access full session transcripts via `sessions_history`? Are there size limits or retention policies that might lose older sessions?

2. **Memory search quality:** Does `memory_search` handle subdirectories well? Does file naming/structure meaningfully affect semantic search quality?

3. **Token economics:** How much does a typical reflection run cost? Is Sonnet sufficient quality for pattern detection, or does it need Opus?

4. **Reflection depth vs breadth:** Should each reflection cover all recent sessions (broad) or go deep on one session? Probably start broad, go deep if patterns emerge.

5. **Auto-apply trust:** When (if ever) should the system auto-apply ADD_RULE changes? What's the threshold for earned trust?

6. **MEMORY.md size management:** As structured memory grows, MEMORY.md should shrink (replaced by references). What's the right target size? 100 lines? 150?

7. **Cross-session learning:** Can lessons from one agent instance (e.g., a sub-agent doing code review) be promoted to the main agent's memory? Should they be?

---

*This spec is a living document. Update it as implementation reveals what works and what doesn't.*
