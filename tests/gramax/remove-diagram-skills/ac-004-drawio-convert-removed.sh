#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-004-drawio-convert-removed.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-004 → plugins/gramax/scripts/drawio_convert.py отсутствует
#
# TDD stub: должен ПАДАТЬ пока Dev не удалит файл.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

TARGET="$ROOT/plugins/gramax/scripts/drawio_convert.py"

assert_file_not_exists "$TARGET" \
  "AC-004: drawio_convert.py must be deleted"

# Boundary: deprecated/ subdirectory must not contain it either (ADR-0008 Решение 2: no deprecated/)
assert_file_not_exists "$ROOT/plugins/gramax/scripts/deprecated/drawio_convert.py" \
  "AC-004: drawio_convert.py must not exist in scripts/deprecated/ either"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-004: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-004: drawio_convert.py absent"
