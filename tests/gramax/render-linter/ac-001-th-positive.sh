#!/usr/bin/env bash
# tests/gramax/render-linter/ac-001-th-positive.sh
# Требование: docs/30-requirements/2026-08-12-render-killer-linter.md — AC-001 (FR-104)
# ADR: docs/00-project/adr/0019-render-killer-linter.md, Решение 3
# Понижение severity (адаптация без ослабления, NFR-083): запись замера
#   docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md —
#   повторный замер волны-2 подтвердил 200 на th-in-table; th понижен ERROR → WARN
#   в обоих носителях (severity="warn" в gramax-render-rules.json + severity-aware
#   киллерный проход validate_render.py). Ассерт переведён на факт вердикта: warn L10,
#   rc=0 (WARN rc не красит — NFR-001), сообщение называет <th> и хранит подсказку
#   замены <td> + header="row".
# Проверка: <th> вне кода → warn с номером строки, exit 0; сообщение с <th> + header="row".

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

assert_eq "$RC" "0" "AC-001: <th> вне кода даёт warn — WARN rc не красит, exit 0 (NFR-001)"

if ! printf '%s\n' "$OUT" | grep -q 'warn  L10'; then
  echo "  FAIL: AC-001 — вывод должен содержать warn с номером строки 10" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT" | grep -q 'ERROR L'; then
  echo "  FAIL: AC-001 — пониженный th не обязан давать ERROR-строк (ERROR L присутствует)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q '<th>'; then
  echo "  FAIL: AC-001 — сообщение должно содержать <th>" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'header="row"'; then
  echo "  FAIL: AC-001 — сообщение должно указывать на <td> + header=\"row\"" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-001: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-001: <th> вне кода → warn L10 с подсказкой <td> + header=\"row\", exit 0"
