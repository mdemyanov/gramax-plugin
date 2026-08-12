#!/usr/bin/env bash
# tests/gramax/render-linter/ac-001-th-positive.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-001 (FR-104)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 3
# Проверка: <th> вне кода → ERROR с номером строки, exit 1; сообщение с <td> + header="row".

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

assert_eq "$RC" "1" "AC-001: <th> вне кода обязан давать exit 1"

if ! printf '%s\n' "$OUT" | grep -q 'ERROR L10'; then
  echo "  FAIL: AC-001 — вывод должен содержать ERROR с номером строки 10" >&2
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
pass_msg "ac-001: <th> вне кода → ERROR L10 с подсказкой <td> + header=\"row\", exit 1"
