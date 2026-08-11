#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-009-hook-template-discoverable.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-003 (FR-037)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 4
#      (plugins/gramax/scripts/pre-commit.sh — копируемый hook-шаблон для потребителя).
# Природа: живой контракт — КРАСНЫЙ на момент создания (hook-шаблон ещё не создан —
#   DEV-001).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

if ! find "$ROOT/plugins/gramax" -iname '*pre-commit*' -o -iname '*hook*' 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-003 — plugins/gramax обязан нести копируемый файл/сниппет для подключения валидатора к pre-commit/CI потребителя (FR-037)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-009: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-009: готовый к копированию hook-шаблон обнаружим"
