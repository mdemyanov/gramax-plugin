#!/usr/bin/env bash
# tests/gramax/render-linter/ac-011-th-severity.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-011 (FR-113)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 8
# Проверка: severity <th> = ERROR безусловно — вывод содержит ERROR и не содержит warn/WARN по <th>.

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

assert_eq "$RC" "1" "AC-011: <th> даёт exit 1 (ERROR, не WARN)"

if ! printf '%s\n' "$OUT" | grep -q 'ERROR'; then
  echo "  FAIL: AC-011 — вывод обязан содержать ERROR по <th>" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT" | grep -q 'warn'; then
  echo "  FAIL: AC-011 — <th> не должен понижаться до warn/WARN" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-011: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-011: severity <th> = ERROR (не WARN), exit 1"
