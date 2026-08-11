#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-002-placeholder-detected.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-012 (FR-046)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 2 (уровень: error)
# Природа: живой контракт — КРАСНЫЙ на момент создания (проверка плейсхолдеров {{...}} в
#   validate_structure.py ещё не реализована — DEV-001).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/placeholder-leak"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-012 — фикстура с {{ИМЯ}} в .doc-root.yaml (code:) и в статье (article.md) обязана давать ненулевой код возврата (FR-046, уровень error по ADR-0012 Решение 2)" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qiE '\{\{|placeholder|плейсхолдер'; then
  echo "  FAIL: AC-012 — сообщение об ошибке обязано упоминать плейсхолдер ({{...}} / placeholder / плейсхолдер)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-002: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-002: плейсхолдер {{ИМЯ}} обнаруживается валидатором"
