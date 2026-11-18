#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-035-dogfood-w034-contract-tags.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-071 (FR-156, догфудинг)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (живые ложные W034 факта 7
# на docs/ репозитория устраняются сужением W034; симуляция SA: ноль новых находок)
# Проверка: прогон на живом docs/ — ложных W034 на канонические теги контракта нет
# Red on 99201c0 (2026-11-18): на docs/ живые ложные находки факта 7 — <view> и <mermaid>
# (docs/10-domain/research/2026-08-11-index-md-at-catalog-root.md,
# docs/30-requirements/2026-08-11-mermaid-file-based-adoption.md).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py docs 2>&1) || true

FALSE_W034=$(echo "$OUT" | grep -E 'W034: .*<(view|mermaid|snippet|openapi|video|icon)>' || true)
if [ -n "$FALSE_W034" ]; then
  echo "  FAIL: AC-071 — живые ложные W034 на канонические теги контракта на docs/ (FR-156):" >&2
  echo "$FALSE_W034" | sed 's/^/    /' >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-035: AC-071 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-035: AC-071 — догфудинг docs/: ложных W034 на теги контракта нет"
