#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-018-check-sh-passes.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-014/NFR-004 → bash scripts/check.sh --fast завершается с exit code 0
#                    (финальный gate: whitespace, JSON-валидность, pre-commit checks)
#
# TDD stub: ПАДАЕТ если check.sh возвращает non-zero или файла нет.
# Note: этот тест может пройти/упасть независимо от остальных — он проверяет целостность всего репо.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

CHECK_SH="$ROOT/scripts/check.sh"

assert_file_exists "$CHECK_SH" \
  "AC-018: scripts/check.sh must exist"

if [ -f "$CHECK_SH" ]; then
  # Run from repo root so check.sh can find its relative paths
  set +e
  bash "$CHECK_SH" --fast > /tmp/check_sh_output_$$.txt 2>&1
  EXIT_CODE=$?
  set -e

  assert_exit_zero "$EXIT_CODE" \
    "AC-018: scripts/check.sh --fast must exit 0 (pre-commit gate)"

  if [ "$EXIT_CODE" -ne 0 ]; then
    echo "  check.sh output:" >&2
    cat /tmp/check_sh_output_$$.txt >&2
  fi

  rm -f /tmp/check_sh_output_$$.txt
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-018: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-018: scripts/check.sh --fast exits 0 (pre-commit gate passes)"
