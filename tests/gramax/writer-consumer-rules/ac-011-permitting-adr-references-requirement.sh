#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-011-permitting-adr-references-requirement.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-011 (FR-076).
# Правка PM (2026-08-11): AC-011 переформулирован в самом требовании. FR-076 называет ADR
# ОЖИДАЕМОЙ, не единственной формой разрешающего документа; проверка идёт по наличию ссылки на
# требование ПО ИМЕНИ ФАЙЛА и по ПОЛНОТЕ ТРИАЖА всех шести тем A–F — не по каталогу
# размещения. Кандидаты ищутся и в content/00-project/adr/, и в content/40-architecture/.
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md — фактически
# принятый разрешающий документ (Accepted), сама объясняет, почему она не ADR: enforcement и
# машиночитаемый контракт закреплены параллельным ADR-0012, здесь только триаж.
#
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания (после правки PM). Диспозиция уже
# существует, ссылается на требование по имени файла и несёт разделы для всех шести тем.
# Тест не проверяет только факт существования файла с нужным именем — это была бы более слабая
# версия критерия, чем задумал PM ("не своди это обратно к проверке существования файла").
# Гейт охраняет: (1) ссылку на требование по имени файла, (2) наличие ВСЕХ ШЕСТИ секций
# триажа (A–F) В ОДНОМ И ТОМ ЖЕ документе-кандидате — если кто-то позже уберёт из диспозиции
# тему или ссылку на требование, гейт покраснеет.
#
# Реализовано явным циклом по кандидатам (не grep|xargs|grep) — по прецеденту ac-002 в этом
# suite'е (см. content/lessons-learned.md, запись 2026-08-11 про vacuous truth в xargs на
# пустом stdin).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
REQ_NAME='2026-08-11-writer-consumer-rules'

CANDIDATES=()
while IFS= read -r f; do
  [ -n "$f" ] && CANDIDATES+=("$f")
done < <(grep -rl "$REQ_NAME" "$ROOT/content/00-project/adr" "$ROOT/content/40-architecture" 2>/dev/null)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
  echo "  FAIL: AC-011 — ни один документ в content/00-project/adr/ или content/40-architecture/ не ссылается на $REQ_NAME по имени файла (FR-076)" >&2
  FAIL=$((FAIL + 1))
else
  FOUND_FULL_TRIAGE=0
  BEST_MISSING=""
  for f in "${CANDIDATES[@]}"; do
    missing=""
    for theme in A B C D E F; do
      if ! grep -qE "^## ${theme}\." "$f" 2>/dev/null; then
        missing="${missing}${theme} "
      fi
    done
    if [ -z "$missing" ]; then
      FOUND_FULL_TRIAGE=1
      break
    fi
    BEST_MISSING="$f: отсутствуют темы [ $missing]"
  done
  if [ "$FOUND_FULL_TRIAGE" -eq 0 ]; then
    echo "  FAIL: AC-011 — ни один документ, ссылающийся на $REQ_NAME, не несёт полный триаж всех шести тем A–F ($BEST_MISSING) — FR-076" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-011: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-011: разрешающий документ ссылается на требование по имени файла и несёт полный триаж тем A–F (regression guard)"
