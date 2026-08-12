#!/usr/bin/env bash
# tests/gramax/render-linter/ac-014-colgroup-allowlist.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-014 (FR-115)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 2 (allowlistedTags)
# Проверка: <colgroup>/<col> в таблице → ни ERROR, ни WARN, exit 0 (BR-002).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-014-colgroup.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "0" "AC-014: <colgroup>/<col> не должны флагаться (exit 0)"
FIND_COUNT=$(printf '%s\n' "$OUT" | grep -cE 'ERROR L[0-9]|warn  L[0-9]' || true)
assert_eq "$FIND_COUNT" "0" "AC-014: <colgroup>/<col> → ни ERROR, ни WARN"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-014: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-014: <colgroup>/<col> в allowlist — ни ERROR, ни WARN"
