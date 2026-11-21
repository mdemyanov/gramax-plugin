#!/usr/bin/env bash
# tests/gramax/render-linter/ac-014-colgroup-allowlist.sh
# Требование: docs/30-requirements/2026-08-12-render-killer-linter.md — AC-014 (FR-115)
# ADR: docs/00-project/adr/0019-render-killer-linter.md, Решение 2 (allowlistedTags)
# Калибровка: docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md
#             («Решения» п.2 — многострочный <colgroup>: новый детектор, ERROR;
#              однострочная форма легальна, allowlist colgroup/col не меняется)
# Проверка: (а) многострочный <colgroup> (открывающий тег на строке целиком) → ERROR
#               «Многострочный <colgroup> → HTTP 500», exit 1 — подтверждённый 500-киллер;
#           (б) однострочный <colgroup>/<col> в таблице → ни ERROR, ни WARN, exit 0 (BR-002).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
MULTI_FIXTURE="$SCRIPT_DIR/fixtures/ac-014-colgroup.md"
SINGLE_FIXTURE="$SCRIPT_DIR/fixtures/ac-014-colgroup-single-line.md"

# --- (а) многострочная форма — подтверждённый 500-киллер (замер 2026-11-21) ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$MULTI_FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "1" "AC-014а (замер 2026-11-21): многострочный <colgroup> → ERROR, exit 1"
if ! printf '%s\n' "$OUT" | grep -q 'ERROR L7'; then
  echo "  FAIL: AC-014а — вывод должен содержать ERROR на строке <colgroup> (L7)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'Многострочный <colgroup> → HTTP 500'; then
  echo "  FAIL: AC-014а — сообщение должно называть 500-киллер (Многострочный <colgroup> → HTTP 500)" >&2
  FAIL=$((FAIL + 1))
fi

# --- (б) однострочная форма — allowlist (BR-002), калибровкой не тронута ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$SINGLE_FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "0" "AC-014б (BR-002): однострочный <colgroup>/<col> — exit 0"
FIND_COUNT=$(printf '%s\n' "$OUT" | grep -cE 'ERROR L[0-9]|warn  L[0-9]' || true)
assert_eq "$FIND_COUNT" "0" "AC-014б (BR-002): однострочная форма → ни ERROR, ни WARN"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-014: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-014: allowlist однострочной формы; многострочная — ERROR по замеру 2026-11-21"
