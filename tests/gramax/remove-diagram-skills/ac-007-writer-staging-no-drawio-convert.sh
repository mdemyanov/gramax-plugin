#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-007-writer-staging-no-drawio-convert.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-007 → plugins/gramax/skills/writer/references/staging.md не содержит drawio_convert.py
#
# TDD stub: должен ПАДАТЬ пока Dev не обновит staging.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

STAGING_REF="$ROOT/plugins/gramax/skills/writer/references/staging.md"

assert_file_exists "$STAGING_REF" \
  "AC-007: writer/references/staging.md must still exist"

assert_no_grep "$STAGING_REF" "drawio_convert.py" \
  "AC-007: staging.md must not reference drawio_convert.py"

# Boundary: check for old conversion step text
assert_no_grep_regex "$STAGING_REF" "Конвертировать .drawio.*svg" \
  "AC-007: old 'Конвертировать .drawio → .svg' step must be removed"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-007: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-007: writer/references/staging.md has no drawio_convert.py references"
