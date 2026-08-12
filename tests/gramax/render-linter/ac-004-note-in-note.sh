#!/usr/bin/env bash
# tests/gramax/render-linter/ac-004-note-in-note.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-004 (FR-107)
# Проверка: <note> вложенный в <note> → ERROR на строке вложенного <note>.

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

assert_eq "$RC" "1" "AC-004: <note> в <note> обязан давать exit 1"

if ! printf '%s\n' "$OUT" | grep -q 'ERROR L9'; then
  echo "  FAIL: AC-004 — вывод должен содержать ERROR на строке вложенного <note> (L9)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'вложен в другой <note>'; then
  echo "  FAIL: AC-004 — сообщение должно упоминать вложенность в другой <note>" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: <note> в <note> → ERROR L9 (вложенный), exit 1"
