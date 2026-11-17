#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-007-single-doc-root.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-007 (FR-128).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 1 — зелёным делают
# коммит A (супермножество enum «Тип контента» + свойство «Плагин» + filterProperties;
# docs/_index.md вбирает роль корневого индекса: разделы-дома + ссылка на журнал) и
# коммит B (git rm content/.doc-root.yaml и content/_index.md — поглощение при слиянии).
# Контракт: в дереве ровно один корень каталога .doc-root.yaml — docs/.doc-root.yaml;
# его модель свойств вобрала значения обоих корней (в т.ч. «Требование»); корневой
# индекс ссылается на индексы домов и журнал.
# Отклонение от буквальной команды AC (find без ограничений глубины), зафиксированное
# с обеими сторонами: literal `find . -name ".doc-root.yaml" -not -path "./.git/*"`
# возвращает 39 отслеживаемых файлов — 37 из них фикстуры suite'ов и payload плагина
# (кл. 6 ECOSYSTEM Решения 3: модели чужих каталогов потребителей, не корни этого
# дерева; они остаются после миграции, и «ровно одна строка» в буквальной формулировке
# недостижимо). Рабочая форма — maxdepth 2: настоящие корни каталога лежат на глубине 2
# (./content/.doc-root.yaml, ./docs/.doc-root.yaml), фикстуры — глубже.
# RED on 8b2db0b (дерево до миграции): два корня (content/ и docs/); enum docs/-корня
# не содержит «Требование» (0); docs/_index.md не ссылается на дома (0 упоминаний _index.md).

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

# FR-128: ровно один .doc-root.yaml на глубине настоящих корней каталога — docs/.
ROOTS=$(find . -maxdepth 2 -name ".doc-root.yaml" -not -path "./.git/*" 2>/dev/null | sort)
CNT=$(printf '%s' "$ROOTS" | grep -c .)
if [ "${CNT:-0}" -ne 1 ] || [ "$ROOTS" != "./docs/.doc-root.yaml" ]; then
  fail "AC-007/FR-128: ожидается ровно один корень ./docs/.doc-root.yaml, найдено ${CNT:-0}:"
  printf '%s\n' "$ROOTS" >&2
fi

# FR-128: модель свойств вобрала значения обоих корней — «Требование» в enum.
if [ ! -f docs/.doc-root.yaml ]; then
  fail "AC-007/FR-128: docs/.doc-root.yaml не найден"
else
  CNT=$(grep -c "Требование" docs/.doc-root.yaml)
  if [ "$CNT" -lt 1 ]; then
    fail "AC-007/FR-128: enum docs/.doc-root.yaml не содержит «Требование» (0 < 1) — модель свойств content/-корня не вобрана (коммит A)"
  fi
fi

# FR-128: docs/_index.md — корневой индекс объединённого каталога
# (разделы-дома + ссылка на lessons-learned.md; ≥ 6 упоминаний _index.md).
if [ ! -f docs/_index.md ]; then
  fail "AC-007/FR-128: docs/_index.md не найден"
else
  CNT=$(grep -c "_index.md" docs/_index.md)
  if [ "$CNT" -lt 6 ]; then
    fail "AC-007/FR-128: docs/_index.md ссылается на _index.md ${CNT} раз (< 6) — роль корневого индекса content/-корня не вобрана (коммит A)"
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-007: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
# shellcheck disable=SC2059  # color codes in the format string are the intended output styling
printf "${GREEN}[PASS]${NC} ac-007: один doc-root docs/, модель свойств объединена, индекс поглотил роль корневого\n"
exit 0
