#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-006-no-bloat-flag-in-help.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-016 (FR-049, граница)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 6
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. Граница «плагин не берёт на
#   себя числовые бюджеты объёма (C11-C14-эквивалент)» уже соблюдена сегодняшним
#   --help — этот тест защищает её от случайного нарушения будущим PR, а не ждёт DEV-001.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

HELP_OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py --help 2>&1)

if echo "$HELP_OUT" | grep -qiE 'bloat|budget|line.?count|token.?budget'; then
  echo "  FAIL: AC-016 — --help не должен содержать опцию про bloat/budget/line-count/token-budget (FR-049: числовые бюджеты объёма — зона потребителя, не плагина)" >&2
  echo "  --- вывод --help ---" >&2
  echo "$HELP_OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-006: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-006: граница FR-049 соблюдена — --help не содержит бюджетных флагов (regression guard)"
