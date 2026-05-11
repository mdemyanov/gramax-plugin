#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-006-writer-drawio-ref-rewritten.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-006 → plugins/gramax/skills/writer/references/drawio.md не содержит drawio_convert.py
#
# TDD stub: должен ПАДАТЬ пока Dev не обновит drawio.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

DRAWIO_REF="$ROOT/plugins/gramax/skills/writer/references/drawio.md"

assert_file_exists "$DRAWIO_REF" \
  "AC-006: writer/references/drawio.md must still exist"

assert_no_grep "$DRAWIO_REF" "drawio_convert.py" \
  "AC-006: drawio.md must not reference drawio_convert.py"

# Boundary: check for the old section header that housed drawio_convert.py
assert_no_grep_regex "$DRAWIO_REF" "Конвертация .drawio.*SVG.*обязательно" \
  "AC-006: old 'Конвертация .drawio → SVG (обязательно)' section must be removed"

# Boundary: old 'Готовый инструмент' block (ADR-0008 Решение 4: deleted section)
assert_no_grep "$DRAWIO_REF" "Готовый инструмент" \
  "AC-006: old 'Готовый инструмент' section must be removed"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-006: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-006: writer/references/drawio.md has no drawio_convert.py references"
