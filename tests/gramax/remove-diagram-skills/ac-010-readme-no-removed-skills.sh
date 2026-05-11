#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-010-readme-no-removed-skills.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-010 → plugins/gramax/README.md не упоминает diagram-on-demand и /gramax:diagrams
#             как доступные skills пользователю
#
# TDD stub: должен ПАДАТЬ пока Dev не обновит README.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

README="$ROOT/plugins/gramax/README.md"

assert_file_exists "$README" \
  "AC-010: plugins/gramax/README.md must exist"

# Exact skill path/name references that must be gone
assert_no_grep "$README" "diagram-on-demand" \
  "AC-010: README must not mention 'diagram-on-demand'"

assert_no_grep "$README" "/gramax:diagrams" \
  "AC-010: README must not mention '/gramax:diagrams' as an available skill"

# Boundary: ensure skill listing section doesn't include these skills
# The word 'diagrams' alone (as a general word) is allowed — we target the skill invocation pattern
assert_no_grep_regex "$README" "gramax:diagram" \
  "AC-010: README must not contain any 'gramax:diagram*' skill invocation"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-010: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-010: README has no references to removed skills"
