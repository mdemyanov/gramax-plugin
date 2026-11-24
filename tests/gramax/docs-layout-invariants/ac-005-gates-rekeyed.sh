#!/usr/bin/env bash
# tests/gramax/docs-layout-invariants/ac-005-gates-rekeyed.sh — копия tests/gramax/archive/docs-migration/ac-005-gates-rekeyed.sh (ADR-0029 Решение 2)
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-005 (FR-126).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 5 — зелёным делает
# коммит D1 (ре-ключ .nauta-gates.yaml; comments C11/C13 на docs/ кроме канона nauta;
# блок documentaryCircuit удаляется ЦЕЛИКОМ, ключ documentaryCircuit: absent НЕ ставится —
# контур переносится, не ликвидируется).
# Контракт: в активных (не-комментарий) строках .nauta-gates.yaml нет литерала content/;
# упоминание documentaryCircuit отсутствует во всех строках; валидатор каталога зелёный.
# RED on 8b2db0b (дерево до миграции): grep documentaryCircuit даёт 3 строки (104, 108, 122).
# Подпроверки 1 и 3 зелёные уже сейчас — это уц-warden'ы (NFR-004 требует их зелёность
# на КАЖДОМ коммите цепочки, включая текущий; принудительно красить честно нельзя).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT" || exit 1

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAIL=0

fail() {
  printf "  ${RED}FAIL:${NC} %s\n" "$1" >&2
  FAIL=$((FAIL + 1))
}

# Маскировка отказа: без файла обе grep-подпроверки прошли бы пусто.
if [ ! -f .nauta-gates.yaml ]; then
  fail "AC-005/FR-126: .nauta-gates.yaml не найден — проверять ре-ключ нечего"
fi

# FR-126: в активных строках гейтов литерала content/ нет.
OUT=$(grep -v '^#' .nauta-gates.yaml 2>/dev/null | grep -n "content/" || true)
if [ -n "$OUT" ]; then
  fail "AC-005/FR-126: литерал content/ в не-комментарий строках .nauta-gates.yaml:"
  printf '%s\n' "$OUT" >&2
fi

# FR-126/ADR Решение 5: блок documentaryCircuit удалён целиком, ключ не установлен.
OUT=$(grep -n "documentaryCircuit" .nauta-gates.yaml 2>/dev/null || true)
if [ -n "$OUT" ]; then
  fail "AC-005/FR-126: упоминание documentaryCircuit осталось в .nauta-gates.yaml (ключ 'absent' ставить нельзя — контур переносится):"
  printf '%s\n' "$OUT" >&2
fi

# FR-126: валидатор документарного контура зелёный (после flip Ф9 корень — docs/).
if ! uv run scripts/validate-content.py >/dev/null 2>&1; then
  fail "AC-005/FR-126: uv run scripts/validate-content.py завершился не нулём — контур не валиден"
fi

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-005: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
# shellcheck disable=SC2059  # color codes in the format string are the intended output styling
printf "${GREEN}[PASS]${NC} ac-005: гейты действуют на docs/, documentaryCircuit отсутствует, валидатор зелёный\n"
exit 0
