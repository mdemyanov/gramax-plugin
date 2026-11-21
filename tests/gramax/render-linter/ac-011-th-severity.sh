#!/usr/bin/env bash
# tests/gramax/render-linter/ac-011-th-severity.sh
# Требование: docs/30-requirements/2026-08-12-render-killer-linter.md — AC-011 (FR-113)
# ADR: docs/00-project/adr/0019-render-killer-linter.md, Решение 8
# Понижение severity (адаптация без ослабления, NFR-083): запись замера
#   docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md —
#   повторный замер волны-2 подтвердил 200; severity <th> = WARN (инверсия ассертов:
#   warn есть, ERROR нет, rc=0). Факт вердикта th по-прежнему проверяется.
# Проверка: severity <th> = WARN — вывод содержит warn по <th> и не содержит ERROR.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-001-th-positive.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "0" "AC-011: <th> даёт exit 0 (WARN rc не красит — NFR-001)"

if ! printf '%s\n' "$OUT" | grep -q 'warn'; then
  echo "  FAIL: AC-011 — вывод обязан содержать warn по <th>" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT" | grep -q 'ERROR L'; then
  echo "  FAIL: AC-011 — пониженный <th> не даёт ERROR-находок (ERROR L присутствует)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-011: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-011: severity <th> = WARN (не ERROR), exit 0"
