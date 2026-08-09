#!/usr/bin/env bash
# tests/gramax/orphan-references/run.sh
# Постоянный гейт: ни один живой файл репозитория не ссылается на удалённые артефакты.
# Реестр — sunset-registry.txt рядом. Обобщение ac-016 из remove-diagram-skills.
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-8

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

REGISTRY="$SCRIPT_DIR/sunset-registry.txt"

if [ ! -f "$REGISTRY" ]; then
  printf "${RED}FAIL${NC}: реестр не найден: %s\n" "$REGISTRY" >&2
  exit 2
fi

# Где ищем. Историю удалённого легитимно хранят CHANGELOG, ADR, отчёты и docs/ —
# они исключены ниже, а не здесь, чтобы список областей оставался читаемым.
SEARCH_PATHS=(plugins scripts tests CLAUDE.md AGENTS.md README.md)

# Архив исключён по принципу, а не по списку имён: tests/gramax/archive/ — замороженные
# свидетельства приёмки прошлых релизов, они обязаны называть удалённые артефакты как
# предмет своих ассертов (ADR-0011, Решение 1). CHANGELOG, ADR и отчёты — то же основание.
EXCLUDE_RE='(^|/)CHANGELOG\.md$|^content/00-project/adr/|^content/60-implementation/|^docs/|^tests/gramax/orphan-references/|^tests/gramax/archive/'

TOTAL=0
while IFS= read -r pattern; do
  case "$pattern" in
    ''|'#'*) continue ;;
  esac

  for path in "${SEARCH_PATHS[@]:-}"; do
    [ -e "$path" ] || continue
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      file="${hit%%:*}"
      if printf '%s\n' "$file" | grep -qE "$EXCLUDE_RE"; then
        continue
      fi
      printf "${RED}FAIL${NC}: остаточная ссылка на '%s': %s\n" "$pattern" "$hit" >&2
      TOTAL=$((TOTAL + 1))
    done <<< "$(grep -rnE "$pattern" "$path" 2>/dev/null || true)"
  done
done < "$REGISTRY"

if [ "$TOTAL" -gt 0 ]; then
  printf "\n${RED}FAILED${NC}: %d остаточных ссылок на удалённые артефакты.\n" "$TOTAL" >&2
  printf "Почини ссылки либо, если упоминание историческое, расширь EXCLUDE_RE.\n" >&2
  exit 1
fi

printf "${GREEN}PASS${NC}: остаточных ссылок на удалённые артефакты нет.\n"
exit 0
