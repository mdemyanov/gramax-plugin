#!/usr/bin/env bash
# tests/gramax/render-linter/ac-005-multiple-images.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-005 (FR-108)
# Проверка: строка с двумя вхождениями ![]( → ERROR с номером строки.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-005-multiple-images.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "1" "AC-005: несколько ![]( в строке обязан давать exit 1"

if ! printf '%s\n' "$OUT" | grep -q 'ERROR L8'; then
  echo "  FAIL: AC-005 — вывод должен содержать ERROR с номером строки 8" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'Несколько'; then
  echo "  FAIL: AC-005 — сообщение должно упоминать несколько изображений" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-005: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-005: два ![]( в строке → ERROR L8, exit 1"
