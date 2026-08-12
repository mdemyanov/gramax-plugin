#!/usr/bin/env bash
# tests/gramax/render-linter/ac-017-multipara-td.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-017 (FR-118)
# Проверка: многоабзацная ячейка <td> (пустые строки между абзацами) → ни ERROR, ни WARN.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-017-multipara-td.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "0" "AC-017: многоабзацная ячейка — exit 0"
FIND_COUNT=$(printf '%s\n' "$OUT" | grep -cE 'ERROR L[0-9]|warn  L[0-9]' || true)
assert_eq "$FIND_COUNT" "0" "AC-017: многоабзацный <td> не флагается"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-017: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-017: многоабзацная ячейка <td> не флагается"
