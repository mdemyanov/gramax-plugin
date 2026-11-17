#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-006-layout-map-resolves-docs.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-006 (FR-127)
# — в редакции PM после останова ветки SA (ADR-0021, Решение 6): первая проверка выполняется
# по ПРАВОЙ стороне пары карты раскладки, т.к. писатель карты (nauta init.sh) захардкоживает
# левую часть content/<home>/, а ручная правка managed-блока не переживает прогон.
# ADR: зелёным делает коммит D3 — перегенерация карты повторным прогоном init.sh (nauta
# 2.22.0) ПОСЛЕ коммита C + ручные правки AGENTS.md вне блоков.
# Контракт: адресная часть каждой пары дома не указывает в content/; docs/00-project/
# встречается в AGENTS.md (переписанные ручные зоны); все шесть домов резолвятся в docs/.
# RED on 8b2db0b (дерево до миграции): правая часть всех шести пар = content/<home>;
# grep -c "docs/00-project/" AGENTS.md = 0.

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

# Маскировка отказа: без файла первая проверка прошла бы пусто.
if [ ! -f AGENTS.md ]; then
  fail "AC-006/FR-127: AGENTS.md не найден — проверять карту раскладки нечего"
fi

# Проверка 1 (скорректированная, по правой стороне пары): адрес content/00-project
# не встречается нигде в AGENTS.md.
OUT=$(grep -n -- "→ content/00-project" AGENTS.md 2>/dev/null || true)
if [ -n "$OUT" ]; then
  fail "AC-006/FR-127: адресная часть пары 00-project указывает в content/:"
  printf '%s\n' "$OUT" >&2
fi

# Проверка 2: переписанные ручные зоны несут docs/00-project/ (коммит D3).
CNT=$(grep -c "docs/00-project/" AGENTS.md 2>/dev/null || true)
if [ -z "$CNT" ]; then CNT=0; fi
if [ "$CNT" -lt 1 ]; then
  fail "AC-006/FR-127: docs/00-project/ не встречается в AGENTS.md (0 < 1) — ручные зоны вне managed-блоков не переписаны (коммит D3)"
fi

# Проверка 3: все шесть домов в карте резолвятся в docs/.
for H in 00-project 10-domain 30-requirements 40-architecture 60-implementation 70-operations; do
  LINE=$(sed -n '/nauta:layout-map:begin/,/nauta:layout-map:end/p' AGENTS.md 2>/dev/null |
    grep -E -- "- content/$H/ →" | head -1)
  if [ -z "$LINE" ]; then
    fail "AC-006/FR-127: пара дома $H не найдена в карте раскладки AGENTS.md"
    continue
  fi
  ADDR=$(printf '%s' "$LINE" | sed -E 's/^.*→[[:space:]]*//' | sed -E 's#/+$##')
  if [ "$ADDR" != "docs/$H" ]; then
    fail "AC-006/FR-127: дом $H резолвится в '$ADDR', ожидалось 'docs/$H'"
  fi
done

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-006: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
# shellcheck disable=SC2059  # color codes in the format string are the intended output styling
printf "${GREEN}[PASS]${NC} ac-006: карта раскладки адресует все шесть дома через docs/\n"
exit 0
