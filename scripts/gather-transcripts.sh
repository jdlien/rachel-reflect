#!/usr/bin/env bash
# gather-transcripts.sh — Export session history for reflection
#
# This is a placeholder/documentation script. Full transcript export
# depends on OpenClaw's session history capabilities.
#
# Usage: ./scripts/gather-transcripts.sh [DAYS]
#   DAYS: number of days of history to gather (default: 7)
#
# Current approach:
# The reflector sub-agent uses OpenClaw's built-in sessions_history
# tool to access recent session transcripts directly. This script
# documents the process and provides a fallback for manual export.

set -euo pipefail

DAYS="${1:-7}"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/rachel-transcripts}"
MEMORY_DIR="${MEMORY_DIR:-$HOME/.openclaw/workspace/memory}"

echo "# Transcript Gathering — $(date +%Y-%m-%d)"
echo ""
echo "## Method 1: OpenClaw sessions_history (preferred)"
echo ""
echo "The reflector sub-agent can access session transcripts directly"
echo "using OpenClaw's built-in tools. No export needed."
echo ""
echo "## Method 2: Daily Logs (fallback)"
echo ""
echo "Daily logs at $MEMORY_DIR/YYYY-MM-DD.md contain session summaries."
echo "These are less detailed than full transcripts but capture key events."
echo ""

# Gather recent daily logs as a fallback
mkdir -p "$OUTPUT_DIR"
echo "Gathering last $DAYS days of daily logs..."

count=0
for i in $(seq 0 "$DAYS"); do
    log_date=$(date -d "-${i} days" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d 2>/dev/null)
    log_file="$MEMORY_DIR/${log_date}.md"
    if [[ -f "$log_file" ]]; then
        cp "$log_file" "$OUTPUT_DIR/"
        count=$((count + 1))
    fi
done

echo "Gathered $count daily log files to $OUTPUT_DIR/"
echo ""
echo "## Method 3: Manual Export"
echo ""
echo "For full session transcripts, use the OpenClaw API:"
echo "  curl -s http://localhost:18789/api/sessions | jq '.[]'"
echo ""
echo "Or from within an agent session:"
echo "  Use sessions_history tool to retrieve recent conversations."
echo ""
echo "## Notes"
echo ""
echo "- Full transcripts can be 10-50K tokens per session"
echo "- Daily logs are typically 200-500 tokens each"
echo "- For token-efficient reflection, daily logs often suffice"
echo "- Reserve full transcripts for deep-dive analysis of specific sessions"
