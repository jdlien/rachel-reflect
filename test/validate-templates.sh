#!/usr/bin/env bash
# validate-templates.sh — Verify all structured memory files have required frontmatter
#
# Usage: ./test/validate-templates.sh [MEMORY_DIR]
#   MEMORY_DIR defaults to ~/.openclaw/workspace/memory
#
# Checks that every .md file in structured memory categories has:
# - A top-level heading (# Title)
# - **Created:** date
# - **Updated:** date
# - ## Summary section

set -euo pipefail

MEMORY_DIR="${1:-$HOME/.openclaw/workspace/memory}"
CATEGORIES=("people" "projects" "decisions" "topics" "lessons" "reflections")

PASS=0
FAIL=0
SKIP=0

echo "# Template Validation — $(date +%Y-%m-%d)"
echo ""

for cat in "${CATEGORIES[@]}"; do
    dir="$MEMORY_DIR/$cat"
    if [[ ! -d "$dir" ]]; then
        echo "## $cat/ — ⚠️  directory missing"
        SKIP=$((SKIP + 1))
        continue
    fi

    files=$(find "$dir" -name "*.md" -type f 2>/dev/null | sort)
    file_count=$(echo "$files" | grep -c . 2>/dev/null || true)
    file_count=$(echo "$file_count" | tr -d '[:space:]')
    [[ -z "$file_count" ]] && file_count=0
    # If find returned nothing, files is empty string which grep -c counts as 0
    [[ -z "$(echo "$files" | tr -d '[:space:]')" ]] && file_count=0

    if [[ "$file_count" -eq 0 ]]; then
        echo "## $cat/ — empty (0 files)"
        continue
    fi

    echo "## $cat/ ($file_count files)"
    echo ""

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        basename=$(basename "$file")
        errors=""

        # Check for top-level heading
        if ! head -5 "$file" | grep -q "^# "; then
            errors="${errors}  - Missing top-level heading (# Title)\n"
        fi

        # Check for Created date
        if ! grep -q "^\*\*Created:\*\*" "$file"; then
            errors="${errors}  - Missing **Created:** field\n"
        fi

        # Check for Updated date
        if ! grep -q "^\*\*Updated:\*\*" "$file"; then
            errors="${errors}  - Missing **Updated:** field\n"
        fi

        # Check for Summary section (except reflections which have different structure)
        if [[ "$cat" != "reflections" ]]; then
            if ! grep -q "^## Summary" "$file"; then
                errors="${errors}  - Missing ## Summary section\n"
            fi
        fi

        # Check for Source field (optional but recommended)
        has_source=true
        if ! grep -q "^\*\*Source:\*\*" "$file"; then
            has_source=false
        fi

        # Check filename convention (lowercase-kebab-case)
        if [[ "$basename" =~ [A-Z] ]] && [[ "$basename" != "YYYY-MM-DD.md" ]]; then
            errors="${errors}  - Filename contains uppercase (should be kebab-case)\n"
        fi

        if [[ -z "$errors" ]]; then
            source_note=""
            if ! $has_source; then
                source_note=" (no Source field — recommended)"
            fi
            echo "- ✅ $basename$source_note"
            PASS=$((PASS + 1))
        else
            echo "- ❌ $basename"
            echo -e "$errors"
            FAIL=$((FAIL + 1))
        fi
    done <<< "$files"

    echo ""
done

echo "---"
echo ""
echo "**Results:** $PASS passed, $FAIL failed, $SKIP skipped"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "⚠️  Some files do not comply with the template format."
    echo "See skill/SKILL.md for the expected template for each category."
    exit 1
fi

echo ""
echo "✅ All structured memory files are template-compliant."
