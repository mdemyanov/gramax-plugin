#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-001-drawio-skill-exists.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-001 → plugins/gramax/skills/drawio/SKILL.md существует и имеет YAML frontmatter с полем description
#
# TDD stub: ПАДАЕТ пока Dev не создаст SKILL.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL="$ROOT/plugins/gramax/skills/drawio/SKILL.md"

assert_file_exists "$SKILL" \
  "AC-001: plugins/gramax/skills/drawio/SKILL.md must exist"

# Check YAML frontmatter starts with ---
if [ -f "$SKILL" ]; then
  FIRST_LINE=$(head -1 "$SKILL")
  if [ "$FIRST_LINE" != "---" ]; then
    echo "  FAIL: AC-001: SKILL.md must start with YAML frontmatter '---', got: '$FIRST_LINE'" >&2
    FAIL=$((FAIL + 1))
  fi

  # Check description field present in frontmatter
  if ! sed -n '1,/^---$/p' "$SKILL" | tail -n +2 | grep -q '^description:'; then
    echo "  FAIL: AC-001: frontmatter must contain 'description:' field" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-001: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-001: drawio/SKILL.md exists with valid YAML frontmatter and description"
