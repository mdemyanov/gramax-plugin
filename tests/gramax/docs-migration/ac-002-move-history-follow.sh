#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-002-move-history-follow.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-002 (FR-124).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 7 коммит C — зелёным
# делает распознанное git-ом переименование (R100, NFR-001/005: move без правок содержимого).
# Контракт: предыстория журнала читается по новому пути через git log --follow.
# RED on 8b2db0b (дерево до миграции): docs/lessons-learned.md не существует, счётчик 0.

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

if [ ! -f docs/lessons-learned.md ]; then
  fail "AC-002/FR-124: docs/lessons-learned.md не существует — переезд не исполнен, истории нечего измерять"
fi

CNT=$(git log --follow --oneline -- docs/lessons-learned.md 2>/dev/null | wc -l | tr -d ' ')
if [ "${CNT:-0}" -lt 2 ]; then
  fail "AC-002/FR-124: git log --follow по docs/lessons-learned.md даёт ${CNT:-0} коммитов (< 2) — переименование не распознано или предыстория потеряна (NFR-001)"
fi

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-002: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
printf "${GREEN}[PASS]${NC} ac-002: история журнала читается через --follow (%s коммитов)\n" "${CNT:-0}"
exit 0
