#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-013-adr-resolves-root-index.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-008 (FR-042)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md (Решение 1) +
#      content/00-project/adr/0015-root-index-inert.md (амендмент, Решение 1)
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. Условие уже выполнено: ADR-0012
#   и ADR-0015 оба существуют и оба упоминают `_index.md` — противоречие FR-042 уже
#   разрешено на уровне ADR (реализация в SKILL.md/JSON — отдельно, DEV-001, AC-009/012).
#   Тест защищает этот факт от исчезновения (например, если кто-то отредактирует старый
#   ADR вопреки конвенции репозитория «старые ADR не редактируются» и уберёт упоминание).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

if ! find "$ROOT/content/00-project/adr" -iname '*.md' -print0 2>/dev/null \
    | xargs -0 grep -l '_index.md' 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-008 — ни один ADR не упоминает _index.md; противоречие FR-042 обязано быть разрешено в ADR (ADR-0012 Решение 1, ADR-0015)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-013: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-013: ADR, разрешающий противоречие про _index.md в корне, существует (regression guard)"
