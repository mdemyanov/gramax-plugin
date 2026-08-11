#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-001-dogfood-clean-exit.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-010, AC-011
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 5
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#   AC-010 закрывает DEV-001 (backfill title/order/language/syntax по content/,
#   резолюция _index.md в корне — ADR-0012 Решение 1 / ADR-0015).
#   AC-011 закрывает DEV-002 (строка подключения этого suite к scripts/check.sh).
#   QA-author НЕ подключает suite к check.sh сам — см. README.md.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# --- AC-010: uv run plugins/gramax/scripts/validate_structure.py content; echo "exit=$?" → exit=0
if DOGFOOD_OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py content 2>&1); then
  DOGFOOD_EXIT=0
else
  DOGFOOD_EXIT=$?
fi

assert_eq "$DOGFOOD_EXIT" "0" \
  "AC-010: 'uv run validate_structure.py content' обязан завершаться exit=0 на собственном content/ (BR-004, FR-044)"

if [ "$DOGFOOD_EXIT" -ne 0 ]; then
  echo "  --- первые 10 строк вывода валидатора (DEV-001: backfill title/order/language/syntax) ---" >&2
  echo "$DOGFOOD_OUT" | head -10 >&2
fi

# --- AC-011: прогон воспроизводится автоматически при каждом PR/коммите — не разовый
# ручной прогон. Точку подключения (DEV-002) ищем в scripts/check.sh.
assert_grep "$ROOT/scripts/check.sh" "tests/gramax/catalog-validator" \
  "AC-011: scripts/check.sh обязан вызывать tests/gramax/catalog-validator/run.sh (DEV-002 подключает восьмым/девятым шагом --full, по прецеденту plugin-contract/doc-paths)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-001: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-001: догфудинг чистый и подключён к повторяемой проверке"
