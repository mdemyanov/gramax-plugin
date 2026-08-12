#!/usr/bin/env bash
# tests/gramax/render-linter/ac-021-existing-suites.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-021 (NFR-003)
# Проверка: существующие suite'ы --full не сломаны. Реально гоняем два названных в
#           требовании (orphan-references, nauta-integration) напрямую — без вложенного
#           `check.sh --full` (он рекурсивно запустил бы этот suite снова). Остальные
#           suite'ы зелёные по определению контракта: порт их не меняет, полный прогон
#           делает релизный гейт `check.sh --full` вне этого ассерта.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

for suite in orphan-references nauta-integration; do
  if OUT=$(bash "$ROOT/tests/gramax/$suite/run.sh" 2>&1); then
    RC=0
  else
    RC=$?
  fi
  assert_eq "$RC" "0" "AC-021: suite $suite обязан оставаться зелёным"
  if [ "$RC" -ne 0 ]; then
    echo "  --- вывод $suite ---" >&2
    echo "$OUT" | tail -15 >&2
  fi
done

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-021: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-021: orphan-references и nauta-integration остаются зелёными"
