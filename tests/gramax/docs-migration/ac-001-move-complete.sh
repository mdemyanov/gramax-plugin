#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-001-move-complete.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-001 (FR-124).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 1 — зелёным делает коммит C
# (чистые git mv content/* docs/, NFR-005).
# Контракт: каталог content/ после переезда не существует; шесть домов и журнал живут
# под docs/ с теми же именами и относительными путями.
# RED on 8b2db0b (дерево до миграции): content/ существует, docs/<home>/_index.md и
# docs/lessons-learned.md отсутствуют.

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

# FR-124: каталог content/ после переезда не существует.
if [ -d content ]; then
  fail "AC-001/FR-124: каталог content/ ещё существует — переезд не исполнен"
fi

# FR-124: переезд тождественный — журнальный файл и индексы домов читаются из docs/.
for f in \
  docs/lessons-learned.md \
  docs/00-project/_index.md \
  docs/30-requirements/_index.md \
  docs/60-implementation/_index.md; do
  if [ ! -f "$f" ]; then
    fail "AC-001/FR-124: ожидался файл $f — не найден"
  fi
done

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-001: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
printf "${GREEN}[PASS]${NC} ac-001: content/ исчез, дома и журнал читаются из docs/\n"
exit 0
