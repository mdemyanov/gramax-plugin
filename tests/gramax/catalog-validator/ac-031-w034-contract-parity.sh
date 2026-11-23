#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-031-w034-contract-parity.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-158 (FR-156, BR-028)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (known_tags вычисляется из
# ОБОИХ контрактов: selfClosingTags + pairedTags из gramax-tags.json — схема FR-156/FR-157;
# ADR-0024 Решение 4)
# Проверка: <view defs="status=done"/> и <mermaid path="./ok.mmd"/> (файл существует) → W034 нет
# Red on 99201c0 (2026-11-18): known_tags строится только из gramax-render-rules.json
# (validate_structure.py:645-651), теги selfClosingTags контракта gramax-tags.json в набор
# не входят — <view> и <mermaid> получают ложные W034 (факт 7 требования).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/w034-contract-parity"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if echo "$OUT" | grep -qF 'W034'; then
  echo "  FAIL: AC-158 — канонические теги контракта (<view>, <mermaid>) не должны получать W034 «неподдерживаемая разметка» (FR-156, BR-028)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-031: AC-158 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-031: AC-158 — канонические теги контракта молчат (паритет W034)"
