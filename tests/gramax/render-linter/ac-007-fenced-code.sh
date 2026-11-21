#!/usr/bin/env bash
# tests/gramax/render-linter/ac-007-fenced-code.sh
# Требование: docs/30-requirements/2026-08-12-render-killer-linter.md — AC-007 (FR-110)
# ADR: docs/00-project/adr/0019-render-killer-linter.md, Решение 5
# Понижение severity (адаптация без ослабления, NFR-083): запись замера
#   docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md —
#   th понижен ERROR → WARN; нога маскирования сохраняется: теги/![](/H1 в коде
#   не флагуются на ЛЮБОМ severity, реальный <th> вне кода ловится (теперь warn).
#   Фикстурный <th> переведён в сбалансированную форму (был открытым): warn-киллер
#   не подавляет баланс th (Решение 4 дизайна волны-2), несбалансированный реальный
#   th добавлял бы балансовый ERROR и затмевал предмет теста — маскирование.
# Проверка: внутри ```-блока <th>, <note>…</note>, ![]( ×2, # H1 — НЕ флагуются;
#           реальный <th> ВНЕ кода в той же фикстуре ловится (warn L17).

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

assert_eq "$RC" "0" "AC-007: реальный <th> вне кода даёт warn — exit 0 (NFR-001)"

# ровно одна находка (warn) — по реальному <th> на строке 17; теги/![](/H1 в коде
# не флагуются ни ERROR, ни warn — иначе находок было бы больше
# (grep 'warn  L' не ловит строку сводки "Итого: ... ERROR=0")
FINDING_COUNT=$(printf '%s\n' "$OUT" | grep -c 'warn  L' || true)
assert_eq "$FINDING_COUNT" "1" "AC-007: в fenced-коде теги и ![]( не должны флагаться (ровно одна находка — реальный <th> вне кода)"
ERROR_COUNT=$(printf '%s\n' "$OUT" | grep -c 'ERROR L' || true)
assert_eq "$ERROR_COUNT" "0" "AC-007: ERROR-находок нет — пониженный th не даёт ERROR"

if ! printf '%s\n' "$OUT" | grep -q 'warn  L17'; then
  echo "  FAIL: AC-007 — реальный <th> вне кода должен ловиться warn'ом на L17" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: fenced-код маскируется (теги/![](#) не флагуются), реальный <th> ловится warn'ом"
