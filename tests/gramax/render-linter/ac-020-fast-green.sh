#!/usr/bin/env bash
# tests/gramax/render-linter/ac-020-fast-green.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-020 (NFR-004)
# Проверка: bash scripts/check.sh --fast → exit 0 (рендер-линтер в --fast не красит гейт).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

set +e
OUT=$(bash "$ROOT/scripts/check.sh" --fast 2>&1)
RC=$?
set -e

assert_eq "$RC" "0" "AC-020: check.sh --fast обязан завершаться exit 0"

if [ "$FAIL" -gt 0 ]; then
  echo "  --- хвост вывода check.sh --fast ---" >&2
  echo "$OUT" | tail -20 >&2
  fail_msg "ac-020: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-020: check.sh --fast зелёный с рендер-линтером"
