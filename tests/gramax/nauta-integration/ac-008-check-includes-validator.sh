#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-008-check-includes-validator.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-7
# AC coverage:
#   AC-9 → check.sh --fast включает validate-content.py и зелёный

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_grep "scripts/check.sh" "validate-content.py" \
  "AC-9: check.sh должен вызывать валидатор content/"
assert_grep "scripts/check.sh" "uv run" \
  "AC-9: валидатор должен запускаться через uv run (PEP 723)"
assert_no_grep "scripts/check.sh" "validate-profile.py" \
  "профильный валидатор не подключается — профилей в gramax нет"

set +e
OUT="$(bash scripts/check.sh --fast 2>&1)"
RC=$?
set -e

if [ "$RC" -ne 0 ]; then
  echo "  FAIL: AC-9: check.sh --fast exit=$RC" >&2
  echo "$OUT" | tail -20 >&2
  FAIL=$((FAIL + 1))
fi

if ! printf '%s\n' "$OUT" | grep -q "content"; then
  echo "  FAIL: AC-9: в выводе check.sh нет шага проверки content/" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-008: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-008: check.sh --fast включает validate-content.py и зелёный"
