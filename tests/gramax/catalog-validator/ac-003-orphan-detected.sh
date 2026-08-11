#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-003-orphan-detected.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-013 (FR-047)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 2 (уровень: warning)
# Природа: живой контракт — КРАСНЫЙ на момент создания (проверка статей-сирот в
#   validate_structure.py ещё не реализована — DEV-001).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/orphan-positive"

# Exit-код не проверяется: orphan по умолчанию warning, не error (ADR-0012 Решение 2) —
# корректная будущая реализация останется exit=0, находка проверяется только по тексту.
OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1)

if ! echo "$OUT" | grep -q "truly-orphan.md"; then
  echo "  FAIL: AC-013 — truly-orphan.md не имеет входящих ссылок внутри каталога, валидатор обязан сообщить о ней (FR-047, эквивалент C10)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qiE 'сирот|orphan'; then
  echo "  FAIL: AC-013 — сообщение обязано называть находку сиротой (сирот.../orphan)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: статья-сирота без входящих ссылок обнаруживается валидатором"
