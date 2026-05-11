#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-005-writer-skill-md-no-drawio-convert.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-005 → plugins/gramax/skills/writer/SKILL.md не содержит drawio_convert.py
#
# TDD stub: должен ПАДАТЬ пока Dev не обновит SKILL.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL_FILE="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_file_exists "$SKILL_FILE" \
  "AC-005: writer/SKILL.md must still exist (only content changes)"

assert_no_grep "$SKILL_FILE" "drawio_convert.py" \
  "AC-005: writer/SKILL.md must not reference drawio_convert.py"

# Boundary: also check the full command pattern that was used
assert_no_grep_regex "$SKILL_FILE" "uv run.*drawio_convert" \
  "AC-005: writer/SKILL.md must not contain 'uv run ... drawio_convert' command"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-005: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-005: writer/SKILL.md has no drawio_convert.py references"
