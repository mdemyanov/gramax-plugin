#!/usr/bin/env bash
# tests/gramax/render-linter/ac-003-note-in-cell.sh
# Требование: docs/30-requirements/2026-08-12-render-killer-linter.md — AC-003 (FR-106)
# Калибровка: docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md
#             («Решения» п.1 — note-in-cell ERROR → WARN по факту рендера 200, FR-196)
# Проверка: <note>, открытый внутри <td>/<th>, → WARN на строке открытия <note>, rc=0;
#           сообщение упоминает <td>/<th> и инлайн-замену; ERROR по конструкции нет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-003-note-in-cell.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "0" "AC-003 (калибровка 2026-11-21): <note> в ячейке → WARN, exit 0"

# WARN на строке открытия <note> (14), а не на родительском <td> (13)
if ! printf '%s\n' "$OUT" | grep -q 'warn  L14'; then
  echo "  FAIL: AC-003 — вывод должен содержать WARN на строке открытия <note> (L14)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q '<td>/<th>'; then
  echo "  FAIL: AC-003 — сообщение должно упоминать <td>/<th>" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'инлайн'; then
  echo "  FAIL: AC-003 — сообщение должно подсказывать инлайн-замену" >&2
  FAIL=$((FAIL + 1))
fi
# Понижение severity: ERROR по этой конструкции быть не должно (замер 2026-11-21)
ERR_COUNT=$(printf '%s\n' "$OUT" | grep -cE 'ERROR L[0-9]' || true)
assert_eq "$ERR_COUNT" "0" "AC-003 (калибровка 2026-11-21): note-in-cell — не ERROR"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: <note> в <td> → WARN L14 (ширины плывут), rc=0 — калибровка 2026-11-21"
