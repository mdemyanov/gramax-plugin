#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-010-tags-contract-exists.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-004 (FR-038)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 3
#      (plugins/gramax/gramax-tags.json — новый файл, корень plugins/gramax/, не scripts/).
# Природа: живой контракт — КРАСНЫЙ на момент создания (файл ещё не создан — DEV-001).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

if ! find "$ROOT/plugins/gramax" -iname '*tag*' \( -iname '*.json' -o -iname '*.yaml' -o -iname '*.yml' \) 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-004 — машиночитаемый файл контракта тегов не найден (FR-038, ADR-0012 Решение 3: gramax-tags.json)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-010: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-010: машиночитаемый файл контракта тегов существует"
