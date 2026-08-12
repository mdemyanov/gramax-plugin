#!/usr/bin/env bash
# tests/gramax/render-linter/ac-003-note-in-cell.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-003 (FR-106)
# Проверка: <note>, открытый внутри <td>/<th>, → ERROR на строке открытия <note>;
#           сообщение упоминает <td>/<th> и инлайн-замену.

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

assert_eq "$RC" "1" "AC-003: <note> в ячейке обязан давать exit 1"

# ERROR на строке открытия <note> (14), а не на <td> (8)
if ! printf '%s\n' "$OUT" | grep -q 'ERROR L14'; then
  echo "  FAIL: AC-003 — вывод должен содержать ERROR на строке открытия <note> (L14)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q '<td>'; then
  echo "  FAIL: AC-003 — сообщение должно упоминать <td>/<th>" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'инлайн'; then
  echo "  FAIL: AC-003 — сообщение должно подсказывать инлайн-замену" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: <note> в <td> → ERROR L14 (<note>), подсказка инлайн, exit 1"
