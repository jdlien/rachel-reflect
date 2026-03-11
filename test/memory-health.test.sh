#!/usr/bin/env bash
# memory-health.test.sh — Test the memory-health.sh script against mock data
#
# Usage: ./test/memory-health.test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HEALTH_SCRIPT="$REPO_DIR/scripts/memory-health.sh"

# Create temp directory for mock memory
MOCK_DIR=$(mktemp -d)
trap "rm -rf $MOCK_DIR" EXIT

PASS=0
FAIL=0

assert_contains() {
    local output="$1"
    local expected="$2"
    local test_name="$3"
    if echo "$output" | grep -q "$expected"; then
        echo "  ✅ $test_name"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $test_name — expected to find: $expected"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local output="$1"
    local expected="$2"
    local test_name="$3"
    if ! echo "$output" | grep -q "$expected"; then
        echo "  ✅ $test_name"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $test_name — expected NOT to find: $expected"
        FAIL=$((FAIL + 1))
    fi
}

assert_exit_code() {
    local actual="$1"
    local expected="$2"
    local test_name="$3"
    if [[ "$actual" -eq "$expected" ]]; then
        echo "  ✅ $test_name"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $test_name — expected exit $expected, got $actual"
        FAIL=$((FAIL + 1))
    fi
}

echo "# memory-health.sh Tests"
echo ""

# --- Test 1: Missing directory ---
echo "## Test 1: Missing memory directory"
output=$("$HEALTH_SCRIPT" "/nonexistent/path" 2>&1 || true)
assert_contains "$output" "not found" "Reports missing directory"

# --- Test 2: Empty categories ---
echo ""
echo "## Test 2: Empty structured memory"
mkdir -p "$MOCK_DIR"/{people,projects,decisions,topics,lessons,reflections}
# Create a mock MEMORY.md
cat > "$MOCK_DIR/../MEMORY.md" 2>/dev/null <<'EOF' || true
# Test Memory
Short file.
EOF
# Actually place it where the script expects
mkdir -p "$(dirname "$MOCK_DIR")"
cat > "$MOCK_DIR/../MEMORY.md" <<'EOF'
# Test Memory
Short file.
EOF

output=$("$HEALTH_SCRIPT" "$MOCK_DIR" 2>&1)
assert_contains "$output" "people/" "Shows people/ category"
assert_contains "$output" "0 files" "Shows 0 files for empty categories"

# --- Test 3: With files ---
echo ""
echo "## Test 3: Populated memory"

# Create compliant files
cat > "$MOCK_DIR/people/test-person.md" <<'EOF'
# Test Person

**Created:** 2026-03-10
**Updated:** 2026-03-10
**Source:** test

## Summary
A test person.

## Details
Testing.

## Open Questions
None.
EOF

cat > "$MOCK_DIR/projects/test-project.md" <<'EOF'
# Test Project

**Created:** 2026-03-10
**Updated:** 2026-03-10
**Source:** test

## Summary
A test project.
EOF

cat > "$MOCK_DIR/lessons/test-lesson.md" <<'EOF'
# Test Lesson

**Created:** 2026-03-10
**Updated:** 2026-03-10
**Source:** test

## Summary
A test lesson.
EOF

output=$("$HEALTH_SCRIPT" "$MOCK_DIR" 2>&1)
assert_contains "$output" "people/" "Lists people category"
assert_contains "$output" "projects/" "Lists projects category"
assert_contains "$output" "lessons/" "Lists lessons category"
assert_contains "$output" "Total structured files" "Reports total count"
assert_contains "$output" "All files have required frontmatter" "All files compliant"

# --- Test 4: Non-compliant file ---
echo ""
echo "## Test 4: Non-compliant file detection"

cat > "$MOCK_DIR/topics/bad-file.md" <<'EOF'
# Bad File
This file has no frontmatter at all.
Just some random content.
EOF

output=$("$HEALTH_SCRIPT" "$MOCK_DIR" 2>&1)
assert_contains "$output" "bad-file.md" "Detects non-compliant file"
assert_contains "$output" "missing:" "Reports what's missing"

# --- Test 5: Daily log count ---
echo ""
echo "## Test 5: Daily log counting"

touch "$MOCK_DIR/2026-03-08.md"
touch "$MOCK_DIR/2026-03-09.md"
touch "$MOCK_DIR/2026-03-10.md"

output=$("$HEALTH_SCRIPT" "$MOCK_DIR" 2>&1)
assert_contains "$output" "Daily log files" "Counts daily logs"

# --- Test 6: MEMORY.md line count ---
echo ""
echo "## Test 6: MEMORY.md size reporting"

# Create a large MEMORY.md (>150 lines)
large_md="$MOCK_DIR/../MEMORY.md"
for i in $(seq 1 160); do
    echo "Line $i of test content" >> "$large_md"
done

output=$("$HEALTH_SCRIPT" "$MOCK_DIR" 2>&1)
assert_contains "$output" "exceeds 150 lines" "Warns about oversized MEMORY.md"

echo ""
echo "---"
echo "Results: $PASS passed, $FAIL failed"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
