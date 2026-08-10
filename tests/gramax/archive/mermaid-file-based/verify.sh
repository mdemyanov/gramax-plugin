#!/usr/bin/env bash
# tests/gramax/archive/mermaid-file-based/verify.sh
# Ручной верификатор выхода gramax:mermaid (FR-015).
#
# Почему не ac-*.sh: проверяемое поведение — результат работы скилла, а не состояние
# репозитория. Автоматизировать в pre-commit нельзя: нужен живой вызов Claude. Прежние
# ac-001…ac-010 это игнорировали — печатали TODO и падали, создавая видимость покрытия.
#
# Использование:
#   1. Создай тестовую статью в пустом каталоге, например /tmp/mtest/docs/auth/overview.md
#   2. Вызови gramax:mermaid на ней (тема — «процесс авторизации», diagram-slug «auth-flow»)
#   3. bash tests/gramax/archive/mermaid-file-based/verify.sh /tmp/mtest
#
# Не входит ни в один режим scripts/check.sh.

set -u -o pipefail

OUT="${1:-}"
if [ -z "$OUT" ]; then
  cat >&2 <<'USAGE'
usage: verify.sh <output-dir>

  <output-dir>  каталог, в котором gramax:mermaid отработал по тестовой статье.
                Ожидаемая структура: <output-dir>/docs/auth/overview.md
                                     <output-dir>/docs/auth/overview-auth-flow.mermaid

Скрипт ручной: сначала вызови скилл, потом передай сюда каталог с результатом.
USAGE
  exit 2
fi

if [ ! -d "$OUT" ]; then
  echo "FAIL: каталог не найден: $OUT" >&2
  exit 2
fi

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
FAIL=0
note() { printf "${RED}FAIL${NC}: %s\n" "$1" >&2; FAIL=$((FAIL + 1)); }

ART="$OUT/docs/auth/overview.md"
DSL="$OUT/docs/auth/overview-auth-flow.mermaid"

# AC-001: файл создан рядом со статьёй
[ -f "$DSL" ] || note "AC-001: .mermaid-файл не создан рядом со статьёй: $DSL"

if [ -f "$DSL" ]; then
  # AC-002: DSL начинается с объявления типа диаграммы
  head -1 "$DSL" | grep -qE '^(flowchart|sequenceDiagram|gantt|classDiagram|stateDiagram-v2|erDiagram|pie|mindmap)' \
    || note "AC-002: первая строка DSL не объявляет поддерживаемый тип диаграммы"

  # AC-007: в .mermaid-файле нет markdown-разметки и ограждений
  grep -qE '^\s*```|^\s*#{1,6} |\*\*' "$DSL" \
    && note "AC-007: .mermaid-файл содержит markdown-разметку — должен нести только DSL"

  # AC-010: нумерованный list-syntax ломает парсер Gramax
  grep -qE '^[[:space:]]*[0-9]+\. ' "$DSL" \
    && note "AC-010: DSL содержит list-syntax '1. ' — конфликтует с парсером"
fi

if [ -f "$ART" ]; then
  # AC-003/004/006: тег-ссылка вставлена, самозакрывающаяся, с width и height
  grep -qE '<mermaid path="\./overview-auth-flow\.mermaid"[^>]*/>' "$ART" \
    || note "AC-003/006: в статье нет самозакрывающегося тега на созданный файл"
  grep -qE '<mermaid[^>]*width="[0-9]+px"[^>]*/>' "$ART" \
    || note "AC-004: у тега нет атрибута width"
  grep -qE '<mermaid[^>]*height="[0-9]+px"[^>]*/>' "$ART" \
    || note "AC-004: у тега нет атрибута height"

  # AC-009: инлайновый блок не должен быть вырезан молча
  grep -qE '^\s*```mermaid' "$ART" && printf 'NOTE: в статье остался inline-блок ```mermaid — проверь, что миграция была подтверждена пользователем, а не сделана молча\n'
else
  note "AC-003: статья не найдена: $ART"
fi

# AC-005b: конвенция имени — <page-slug>-<diagram-slug>.mermaid
# Через process substitution (< <(...)), а не pipe (find | while): pipe запускал бы while
# в подоболочке, и note()'вский FAIL=$((FAIL+1)) внутри неё терялся бы при возврате в основной
# shell — скрипт печатал бы FAIL в stderr, но всё равно выходил бы нулём.
while IFS= read -r -d '' f; do
  base="$(basename "$f" .mermaid)"
  echo "$base" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)+$' \
    || note "AC-005b: имя '$base' не соответствует конвенции <page-slug>-<diagram-slug>"
done < <(find "$OUT" -name '*.mermaid' -print0 2>/dev/null)

if [ "$FAIL" -gt 0 ]; then
  printf "\n${RED}FAILED${NC}: %d проверок не прошли.\n" "$FAIL" >&2
  exit 1
fi
# shellcheck disable=SC2059  # GREEN/NC — литеральные ANSI-коды без '%', интерполяция безопасна
printf "\n${GREEN}PASS${NC}: выход gramax:mermaid соответствует file-based контракту.\n"
exit 0
