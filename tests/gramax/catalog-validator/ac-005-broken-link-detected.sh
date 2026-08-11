#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-005-broken-link-detected.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-015 (FR-048)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 2 (уровень: error)
# Природа: живой контракт — КРАСНЫЙ на момент создания (проверка битых ссылок в
#   validate_structure.py ещё не реализована — DEV-001).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/broken-link"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-015 — ссылка на несуществующий ./missing-file.md обязана давать ненулевой код возврата (FR-048, уровень error по ADR-0012 Решение 2)" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qiE 'missing-file|битая|broken'; then
  echo "  FAIL: AC-015 — сообщение об ошибке обязано называть недостающий файл или упоминать 'битая'/'broken' ссылку" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-005: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-005: битая markdown-ссылка обнаруживается валидатором"
