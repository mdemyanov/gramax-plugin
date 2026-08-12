#!/usr/bin/env bash
# tests/gramax/render-linter/ac-007-fenced-code.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-007 (FR-110)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 5
# Проверка: внутри ```-блока <th>, <note>…</note>, ![]( ×2, # H1 — НЕ флагаются;
#           реальный <th> ВНЕ кода в той же фикстуре ловится (AC-001).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-007-fenced-code.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "1" "AC-007: реальный <th> вне кода обязан давать exit 1"

# ровно одна ERROR-находка — по реальному <th> на строке 17
# (grep 'ERROR L' не ловит строку сводки "Итого: ... ERROR=1")
ERROR_COUNT=$(printf '%s\n' "$OUT" | grep -c 'ERROR L' || true)
assert_eq "$ERROR_COUNT" "1" "AC-007: в fenced-коде теги и ![]( не должны флагаться (одна ERROR — реальный <th>)"

if ! printf '%s\n' "$OUT" | grep -q 'ERROR L17'; then
  echo "  FAIL: AC-007 — реальный <th> вне кода должен ловиться на L17" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: fenced-код маскируется (теги/![](#) не флагаются), реальный <th> ловится"
