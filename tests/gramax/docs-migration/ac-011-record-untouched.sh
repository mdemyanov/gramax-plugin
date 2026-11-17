#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-011-record-untouched.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-011 (NFR-003).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 3 (якорь RECORD) —
# зелёным делает коммит C: ADR-0009 доезжает до docs/00-project/adr/ строка-в-строку.
# Контракт: RECORD-строки исторических ADR не переписываются — строка 272 ADR-0009
# содержит docs/adr/ ДОСЛОВНО (упоминание старой раскладки в записи о решении легально;
# замена пути превратила бы запись в утверждение о сегодняшней раскладке).
# RED on 8b2db0b (дерево до миграции): файл ещё читается только по пути content/.

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

F="docs/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md"
if [ ! -f "$F" ]; then
  fail "AC-011/NFR-003: ADR-0009 не читается по послемиграционному пути $F (файл ещё на content/ — переезд не исполнен)"
else
  LINE=$(sed -n '272p' "$F")
  if ! printf '%s' "$LINE" | grep -qF "docs/adr/"; then
    fail "AC-011/NFR-003: строка 272 ADR-0009 не содержит docs/adr/ дословно (RECORD переписан?): '${LINE}'"
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-011: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
printf "${GREEN}[PASS]${NC} ac-011: RECORD-строка 272 ADR-0009 сохранена дословно (docs/adr/ на месте)\n"
exit 0
