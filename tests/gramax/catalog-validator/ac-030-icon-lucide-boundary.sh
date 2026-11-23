#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-030-icon-lucide-boundary.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-066 (FR-153, BR-013)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (lucide-код против .icons/);
# ПЕРЕВЕДЕНО под волну-3 (NFR-084): ADR-0026 Решение 3 — superseded в части формы префикса.
# Новая семантика: голый код zap (в реестре) — W035 НЕТ; lucide-zap без файла — W035 ЕСТЬ,
# с подсказкой убрать префикс (дизайн волны-3 §2.4, сообщение дословно).
# Проверка: <icon code="zap"/> и <icon code="lucide-zap"/> без .icons/ →
#   (a) вывод НЕ содержит W035 по голому zap; (b) вывод содержит W035 по lucide-zap
#   с подсказкой про префикс.
# Red on 7553da1 (2026-11-23): реестра нет (BR-013 старой редакции) — голый zap даёт W035,
#   lucide-zap молчит: обе ноги красные до цикла Dev.
# История: до волны-3 ассерт был «lucide-zap не упоминается» — зелёный warden на 99201c0;
# перевод (не удаление) — по таблице «Существующие ассерты, которые меняют цвет»
# дизайн-документа волны-3 и NFR-084.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/icons-lucide"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

# (a): голый zap из реестра — без файла находки нет (реестр молчит за файл)
if printf '%s\n' "$OUT" | grep "W035" | grep -qF 'код "zap"'; then
  echo "  FAIL: AC-066 (волна-3) — W035 на голом коде zap: код входит в реестр lucide-react 0.525.0, W035 = нет файла И нет в реестре (ADR-0026 Решение 3)" >&2
  FAIL=$((FAIL + 1))
fi

# (b): lucide-zap без файла — W035 с подсказкой убрать префикс
if ! printf '%s\n' "$OUT" | grep "W035" | grep -qF 'lucide-zap'; then
  echo "  FAIL: AC-066 (волна-3) — lucide-zap без .icons/ обязан давать W035: формы с префиксом lucide- движок не читает (LucideIcon.ts:36-42)" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep "W035" | grep -F 'lucide-zap' | grep -qi "префикс"; then
  echo "  FAIL: AC-066 (волна-3) — W035 на lucide-zap обязан нести подсказку убрать префикс (дизайн волны-3 §2.4 дословно)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-030: AC-066 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-030: AC-066 — голый zap молчит (реестр), lucide-zap даёт W035 с подсказкой (ADR-0026 Решение 3)"
