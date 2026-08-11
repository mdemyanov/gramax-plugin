#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-007-readme-discoverability.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-001 (FR-035)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 4 (новый
#      заголовок «## Валидация каталога», четвёртым — после «## Установка», «## Skills»,
#      перед «## Agents»/«## Scripts»).
# Природа: живой контракт — КРАСНЫЙ на момент создания (README-раздел ещё не создан —
#   DEV-001). Suite тут, не в plugin-contract, потому что подключён к check.sh --full не
#   этот suite, а тот — красный ассерт в plugin-contract заблокировал бы коммиты до конца
#   DEV-001 (см. at-design.md, раздел «Почему здесь, не в plugin-contract»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
README="$ROOT/plugins/gramax/README.md"

assert_file_exists "$README" "AC-001: plugins/gramax/README.md должен существовать"

if [ -f "$README" ]; then
  if ! grep -n '^## ' "$README" | head -6 | grep -qi 'валидац\|validate'; then
    echo "  FAIL: AC-001 — валидатор обязан упоминаться в одном из первых 6 заголовков '## ' README.md (FR-035)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: валидатор обнаружим в первых заголовках README"
