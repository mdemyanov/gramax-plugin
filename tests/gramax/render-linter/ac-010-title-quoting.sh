#!/usr/bin/env bash
# tests/gramax/render-linter/ac-010-title-quoting.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-010 (FR-112)
# Проверка: frontmatter `title: А: Б` без кавычек → WARN, exit 0;
#           `title: "А: Б"` в кавычках → чисто (нет WARN), exit 0.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
UNQ="$SCRIPT_DIR/fixtures/ac-010-title-unquoted.md"
Q="$SCRIPT_DIR/fixtures/ac-010-title-quoted.md"

# --- незакавыченный title с ': ' ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$UNQ" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "0" "AC-010: title без кавычек — WARN, exit 0"
if ! printf '%s\n' "$OUT" | grep -q 'warn'; then
  echo "  FAIL: AC-010 — незакавыченный title с ': ' обязан давать WARN" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'без кавычек'; then
  echo "  FAIL: AC-010 — сообщение должно упоминать кавычки" >&2
  FAIL=$((FAIL + 1))
fi

# --- закавыченный title → чисто ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$Q" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "0" "AC-010: title в кавычках — exit 0"
FIND_COUNT=$(printf '%s\n' "$OUT" | grep -cE 'ERROR L[0-9]|warn  L[0-9]' || true)
assert_eq "$FIND_COUNT" "0" "AC-010: title в кавычках не должен давать находок"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-010: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-010: title без кавычек → WARN; title в кавычках → чисто"
