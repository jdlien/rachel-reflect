---
name: rachel-reflect
description: Self-reflection and structured memory system for OpenClaw agents. Provides a learning loop through session analysis, structured knowledge organization, and automated memory maintenance.
tags:
  - memory
  - reflection
  - self-improvement
  - knowledge-management
  - productivity
---

# rachel-reflect — Self-Reflection & Structured Memory

A skill that gives OpenClaw agents the ability to learn from their sessions, organize knowledge into a structured memory system, and maintain memory health over time.

## Overview

This skill provides two complementary processes:

1. **Reflector** — Analyzes recent sessions and daily logs to identify mistakes, successes, and missing knowledge. Produces a reflection report with proposed changes.
2. **Librarian** — Maintains the structured memory system by promoting durable observations from daily logs, pruning stale knowledge, and keeping MEMORY.md lean.

Both processes run as **isolated sub-agent sessions** to avoid bloating the main conversation context.

---

## Structured Memory System

### Directory Layout

All structured memory lives under `memory/` in the workspace:

```
memory/
├── YYYY-MM-DD.md          # Daily logs (raw, chronological — Tier 2)
├── people/                 # One file per significant person
├── projects/               # One file per active/recent project
├── decisions/              # Significant decisions with reasoning
├── topics/                 # Domain knowledge and expertise
├── lessons/                # Learned behaviors, rules, and corrections
├── reflections/            # Reflection and librarian reports
├── heartbeat-state.json    # Heartbeat tracking
└── librarian-state.json    # Librarian last-processed tracking
```

### Memory Tiers

| Tier | Location | Loaded When | Purpose |
|------|----------|-------------|---------|
| 1 | MEMORY.md | Every main session | Curated summary with references to Tier 3 |
| 2 | memory/YYYY-MM-DD.md | Recent days only | Raw daily logs, source material |
| 3 | memory/{category}/*.md | On-demand via search | Durable structured knowledge |

### File Templates

Every structured memory file follows a consistent format. Use the appropriate template below.

#### People Template (`memory/people/`)

```markdown
# [Full Name]

**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Source:** [how we know them — project, email, conversation]

## Summary
[1-3 sentences: who they are, their role, relationship to us]

## Details
- **Role/Title:** [job title or role]
- **Organization:** [company/org]
- **Contact:** [email, phone if known]
- **Relationship:** [client, colleague, vendor, friend, family]

[Additional context, personality notes, communication preferences, history]

## Open Questions
[Things we don't know yet about this person]
```

#### Projects Template (`memory/projects/`)

```markdown
# [Project Name]

**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Source:** [project origin — client request, internal, etc.]

## Summary
[1-3 sentences: what it is, current status, who it's for]

## Details
- **Tech Stack:** [languages, frameworks, infrastructure]
- **Client/Owner:** [who it's for]
- **Status:** [active/paused/complete]
- **Priority:** [primary/secondary/background]
- **Deadline:** [if any]
- **Billing:** [how it's billed]

### Key Contacts
[People involved and their roles]

### Recent Activity
[Latest developments, milestones, blockers]

### History
[Major milestones, decisions, pivots]

## Open Questions
[Unresolved issues, pending decisions]
```

#### Decisions Template (`memory/decisions/`)

```markdown
# [Decision Title]

**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Source:** [conversation, email, meeting that led to this]

## Summary
[1-3 sentences: what was decided and why]

## Context
[What situation required a decision]

## Options Considered
[What alternatives were evaluated]

## Decision
[What was chosen and the reasoning]

## Consequences
[Known outcomes, trade-offs accepted]

## Open Questions
[Unresolved follow-ups]
```

#### Topics Template (`memory/topics/`)

```markdown
# [Topic Title]

**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Source:** [how this knowledge was gained — debugging, research, etc.]

## Summary
[1-3 sentences: what this topic covers]

## Details
[Full knowledge, patterns, best practices, gotchas]

## Related
[Links to related topics, projects, or lessons]

## Open Questions
[Things still unknown or uncertain]
```

#### Lessons Template (`memory/lessons/`)

```markdown
# [Lesson Title]

**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Source:** [session or event that taught this lesson]

## Summary
[1-3 sentences: the core lesson]

## Context
[What happened that led to this lesson]

## Rule
[The specific behavioral rule or guideline to follow]

## Examples
[Concrete examples of when this applies]
```

#### Reflections Template (`memory/reflections/`)

```markdown
# Reflection — YYYY-MM-DD

## Session Coverage
- Analyzed sessions: [list or count]
- Daily logs reviewed: YYYY-MM-DD through YYYY-MM-DD

## Findings

### 🔴 Mistakes & Inefficiencies
[Things done wrong, handled poorly, or done wastefully]

### 🟢 Successful Patterns
[Things done well, good judgment calls, effective approaches]

### 🟡 Missing Knowledge
[Context that should have been stored but wasn't]

### 🔵 Behavioral Notes
[Tone, personality, boundary, and relationship observations]

## Proposed Changes
| # | Type | Target | Description |
|---|------|--------|-------------|
| 1 | ADD_LESSON | memory/lessons/... | ... |
| 2 | ADD_KNOWLEDGE | memory/people/... | ... |
```

---

## Process 1: Self-Reflection (Reflector)

### When to Run
- **Scheduled:** Every 2-3 days via cron (isolated session)
- **On-demand:** When asked to reflect, or via `/reflect`
- **Heartbeat:** "Run reflection if >3 days since last" in HEARTBEAT.md

### Input Sources
1. **Daily log files** — `memory/YYYY-MM-DD.md` (last 3-7 days)
2. **Session history** — via `sessions_history` if available
3. **Current rules** — AGENTS.md, SOUL.md, TOOLS.md
4. **Existing lessons** — `memory/lessons/` directory

### Reflection Prompt

When running a reflection, follow this structured analysis:

```
## Reflection Analysis

Review the recent daily logs and any available session transcripts.
Identify findings in each category:

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

### Output
Save the reflection report to `memory/reflections/YYYY-MM-DD.md` using the reflections template above.

### Applying Changes

After generating the report, apply changes based on trust level:

| Change Type | Auto-Apply? | Requires Review? |
|-------------|------------|-----------------|
| ADD_KNOWLEDGE (people, projects, topics) | ✅ Yes | No |
| ADD_LESSON (learned behaviors) | ✅ Yes | No |
| UPDATE_KNOWLEDGE (modify existing) | ✅ Yes | No |
| ADD_RULE (AGENTS.md, TOOLS.md) | ❌ No | Yes — agent reviews |
| UPDATE_IDENTITY (IDENTITY.md) | ❌ No | Yes — human reviews |
| UPDATE_SOUL (SOUL.md) | ❌ Never | Always — human only |

---

## Process 2: Memory Maintenance (Librarian)

### When to Run
- **Scheduled:** Weekly via cron (isolated session, e.g. Monday 6 AM)
- **On-demand:** When asked to organize or maintain memory
- **Heartbeat:** "Run librarian if >7 days since last" in HEARTBEAT.md

### The DURA Test

An observation in a daily log is worth promoting to structured memory if it passes:

| Criterion | Question |
|-----------|----------|
| **D**urability | Will this matter in 30+ days? |
| **U**niqueness | Is this new information, not already captured? |
| **R**etrievability | Will I want to recall this later? |
| **A**uthority | Is this reliable information (not speculation)? |

### Librarian Process

**Step 1: Scan recent daily logs**
Read daily logs since the last librarian run. Check `memory/librarian-state.json` for the last-processed date:

```json
{
  "lastRun": "YYYY-MM-DD",
  "lastProcessedLog": "YYYY-MM-DD"
}
```

**Step 2: Identify promotable content**
For each daily log, find observations that pass DURA:
- New person with significant context → `memory/people/`
- Project milestone or status change → `memory/projects/`
- Decision made with reasoning → `memory/decisions/`
- Technical knowledge gained → `memory/topics/`
- Lesson learned from mistake → `memory/lessons/`

**Step 3: Create or update structured files**
- New knowledge → create file using the appropriate template
- Existing knowledge updated → update the file, bump the `Updated` date
- Log each action taken

**Step 4: Slim MEMORY.md**
If MEMORY.md exceeds ~150 lines, replace verbose sections with references:

```markdown
### Pronghorn
See [memory/projects/pronghorn.md](memory/projects/pronghorn.md) for full details.
Current status: [brief one-liner]
```

**Step 5: Generate maintenance report**
Save to `memory/reflections/librarian-YYYY-MM-DD.md`:

```markdown
# Librarian Report — YYYY-MM-DD

## Processed
- Daily logs: YYYY-MM-DD through YYYY-MM-DD

## Actions Taken
- Created: [list of new files]
- Updated: [list of updated files]
- Pruned: [MEMORY.md sections replaced with references]

## Memory Health
- Total structured files: [count]
- Files updated in last 30 days: [count]
- MEMORY.md length: [lines] (target: <150)
- Stale files (>90 days without update): [count]
```

**Step 6: Update librarian state**
Write the current date to `memory/librarian-state.json`.

---

## Scheduling (Cron Configuration)

### Reflector — Every 3 Days

```javascript
{
  name: "rachel-reflect",
  schedule: { kind: "every", everyMs: 259200000 },
  sessionTarget: "isolated",
  payload: {
    kind: "agentTurn",
    message: "Run self-reflection. Read the rachel-reflect skill and follow the Reflector process. Analyze the last 3-7 days of daily logs.",
    model: "anthropic/claude-sonnet-4-20250514"
  }
}
```

### Librarian — Weekly (Monday 6 AM)

```javascript
{
  name: "rachel-librarian",
  schedule: { kind: "cron", expr: "0 6 * * 1", tz: "America/Edmonton" },
  sessionTarget: "isolated",
  payload: {
    kind: "agentTurn",
    message: "Run the librarian maintenance pass. Read the rachel-reflect skill and follow the Librarian process.",
    model: "anthropic/claude-sonnet-4-20250514"
  }
}
```

---

## Tips

- **Token budget:** Each reflection processes ~10-50K tokens of transcript, produces ~1-2K token reports. Negligible cost at Sonnet pricing.
- **Cheaper models work:** Both reflector and librarian are analytical, not creative. Sonnet or even Haiku can handle them.
- **Start manual:** Run both processes manually a few times before enabling cron automation. Review the output quality.
- **Git everything:** All structured memory files should be in a git-tracked workspace for easy rollback.
- **MEMORY.md stays lean:** It's loaded every main session. Keep it under 150 lines by offloading details to structured files.
