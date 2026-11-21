#!/usr/bin/env bash
# tests/gramax/render-linter/ac-004-note-in-note.sh
# Требование: docs/30-requirements/2026-08-12-render-killer-linter.md — AC-004 (FR-107)
# Калибровка: docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md
#             («Решения» п.1 — note-in-note ERROR → WARN по факту рендера 200, FR-196)
# Проверка: <note> вложенный в <note> → WARN на строке вложенного <note>, rc=0;
#           ERROR по конструкции нет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-004-note-in-note.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "0" "AC-004 (калибровка 2026-11-21): <note> в <note> → WARN, exit 0"

if ! printf '%s\n' "$OUT" | grep -q 'warn  L9'; then
  echo "  FAIL: AC-004 — вывод должен содержать WARN на строке вложенного <note> (L9)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'вложен в <note>'; then
  echo "  FAIL: AC-004 — сообщение должно упоминать вложенность в <note>" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'схлопываются'; then
  echo "  FAIL: AC-004 — сообщение должно называть симптом (схлопываются)" >&2
  FAIL=$((FAIL + 1))
fi
# Понижение severity: ERROR по этой конструкции быть не должно (замер 2026-11-21)
ERR_COUNT=$(printf '%s\n' "$OUT" | grep -cE 'ERROR L[0-9]' || true)
assert_eq "$ERR_COUNT" "0" "AC-004 (калибровка 2026-11-21): note-in-note — не ERROR"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: <note> в <note> → WARN L9 (схлопываются), rc=0 — калибровка 2026-11-21"
