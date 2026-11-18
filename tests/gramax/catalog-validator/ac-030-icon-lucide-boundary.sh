#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-030-icon-lucide-boundary.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-066 (FR-153, BR-013)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (lucide-код против .icons/
# не резолвится — только форма префикса; ADR-0024 Решение 5; пограничный случай xlucide-zap —
# кастомный, вне этого AC)
# Проверка: <icon code="lucide-zap"/> без .icons/ → вывод НЕ упоминает 'lucide-zap'
# Warden (зелёный при рождении, 99201c0): проверки иконок нет — упоминаний ноль уже сегодня;
# ассерт защищает границу префикса после реализации: W035 не имеет права резолвить
# lucide-коды против .icons/ (реестра lucide в поставке нет — Решение 5 ADR-0024).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/icons-lucide"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if echo "$OUT" | grep -qF 'lucide-zap'; then
  echo "  FAIL: AC-066 — код с префиксом 'lucide-' не резолвится против .icons/: вывод НЕ должен упоминать 'lucide-zap' (FR-153, BR-013)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-030: AC-066 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-030: AC-066 — lucide-код против .icons/ не резолвится"
