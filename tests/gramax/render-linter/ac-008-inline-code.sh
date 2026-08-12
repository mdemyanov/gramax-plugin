#!/usr/bin/env bash
# tests/gramax/render-linter/ac-008-inline-code.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-008 (FR-110)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 5
# Проверка: `<note>`, `<tabs>`, `<th>` в прозе как inline-код → ни ERROR, ни WARN, exit 0.
# Регрессия на BA факт 2: исходник коллег давал на inline-коде 11 ложных ERROR.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-008-inline-code.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "0" "AC-008: inline-код не должен давать ни ERROR, ни WARN (exit 0)"

# grep 'ERROR L'/'warn  L' — находки-строки, не сводка "Итого: ... ERROR=0"
FIND_COUNT=$(printf '%s\n' "$OUT" | grep -cE 'ERROR L[0-9]|warn  L[0-9]' || true)
assert_eq "$FIND_COUNT" "0" "AC-008: inline-код '<note>'/'<tabs>'/'<th>' не должен флагаться"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-008: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-008: inline-код '<note>'/'<tabs>'/'<th>' не флагается (регрессия на факт 2)"
