#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-009-doc-paths-subject-gone.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-009 (FR-130).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 4 — зелёным делает
# коммит C (content/ исчезает физически; ADR-0021 сам переезжает в docs/00-project/adr/).
# Контракт: предмет suite doc-paths («несвежие docs/-указатели внутри content/»)
# исчез физически — сканируемого каталога нет; решение по судьбе suite (ретирмент,
# ADR-0021 Решение 4) зафиксировано в ADR инверсии (упоминание doc-paths ≥ 1).
# Судьба suite — решение SA, здесь не пере-проверяется (только факт + запись в ADR).
# RED on 8b2db0b (дерево до миграции): content/ существует; ADR по послемиграционному
# пути docs/00-project/adr/0021-docs-layout-inversion.md ещё не читается.

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

# FR-130: сканируемого каталога content/ больше нет — предмет suite doc-paths исчез.
if [ -d content ]; then
  fail "AC-009/FR-130: каталог content/ ещё существует — предмет suite doc-paths не исчез"
fi

# FR-130: решение по suite doc-paths зафиксировано в ADR инверсии
# (ADR-0021, Решение 4 — ретирмент; номер/путь ADR закреплены в нём же: ADR переезжает
# вместе с миграцией и после коммита C читается из docs/00-project/adr/).
ADR="docs/00-project/adr/0021-docs-layout-inversion.md"
if [ ! -f "$ADR" ]; then
  fail "AC-009/FR-130: ADR инверсии не читается по послемиграционному пути $ADR"
else
  CNT=$(grep -c "doc-paths" "$ADR")
  if [ "$CNT" -lt 1 ]; then
    fail "AC-009/FR-130: в ADR инверсии нет решения по suite doc-paths (0 упоминаний < 1)"
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-009: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
printf "${GREEN}[PASS]${NC} ac-009: предмет doc-paths исчез, решение зафиксировано в ADR-0021\n"
exit 0
