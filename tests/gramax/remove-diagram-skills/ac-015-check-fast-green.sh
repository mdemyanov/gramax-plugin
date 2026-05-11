#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-015-check-fast-green.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-015 → bash scripts/check.sh --fast завершается с exit code 0
#             (whitespace + JSON validity gate passes after all removals)
#
# TDD stub: может упасть по разным причинам до реализации.
# После Dev: exit 0.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

CHECK_SH="$ROOT/scripts/check.sh"

assert_file_exists "$CHECK_SH" \
  "AC-015: scripts/check.sh must exist"

# Run the fast check from repo root
CHECK_OUTPUT="$(bash "$CHECK_SH" --fast 2>&1)" || CHECK_EXIT=$?
CHECK_EXIT="${CHECK_EXIT:-0}"

assert_exit_zero "$CHECK_EXIT" \
  "AC-015: 'bash scripts/check.sh --fast' must exit 0"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-015: $FAIL assertion(s) failed"
  if [ -n "$CHECK_OUTPUT" ]; then
    echo "  check.sh output:" >&2
    echo "$CHECK_OUTPUT" | head -20 >&2
  fi
  exit 1
fi
pass_msg "ac-015: scripts/check.sh --fast exits 0"
