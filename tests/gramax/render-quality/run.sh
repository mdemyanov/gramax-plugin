#!/usr/bin/env bash
# tests/gramax/render-quality/run.sh
# Агрегатор сюиты render-quality — дом-паттерн tests/gramax/render-linter/run.sh. Состав —
# ADR-0027 (docs/00-project/adr/0027-full-gate-composition.md, Решения 1-2; поправляет
# Решение 7 дизайна docs/40-architecture/2026-11-21-playwright-render-quality-design.md
# в части живой ноги — superseded-цепочка в ADR-0027 Решение 1):
#   по умолчанию исполняются ТОЛЬКО офлайн-стабы ac-*.sh (цикл по glob, свод, rc
#   «хоть один красный»); им экспортируется UV_OFFLINE=1 — сеть не запрашивается
#   (стаб-портал слушает только 127.0.0.1, пин playwright решается тёплым кэшем uv;
#   промах кэша ловит сигнатура обёртки probe.sh — ADR-159). Живой прогон прибора —
#   именованный шаг scripts/render-quality/live.sh релизного ритуала; агрегатор и гейт
#   не вызывают его ни в каком режиме (NFR-085: в --full нет сети, проб и токена;
#   автоматического офлайн-фолбэка нет — ADR-0027 Решение 2).
# Шаг --full-блока scripts/check-gramax.sh (==> render-quality). В --fast сюиты нет
# (NFR-078, варден ac-118).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Офлайн по построению: стабы сети не требуют; UV_OFFLINE=1 запрещает uv обращаться
# к pypi (ADR-0027 Решение 2 — сеть в пути гейта не запрашивается).
export UV_OFFLINE=1

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass=0
fail=0
failed_tests=()

shopt -s nullglob
tests=(ac-*.sh)
shopt -u nullglob

if [ ${#tests[@]} -eq 0 ]; then
  printf "${RED}No ac-*.sh tests found in %s${NC}\n" "$SCRIPT_DIR"
  exit 2
fi

printf "${YELLOW}Running %d AC stubs from %s (offline: UV_OFFLINE=1)%b\n\n" "${#tests[@]}" "$SCRIPT_DIR" "$NC"

for t in "${tests[@]}"; do
  if bash "$t"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failed_tests+=("$t")
  fi
done

printf "\n%b━━━ Summary (offline stubs) ━━━%b\n" "$YELLOW" "$NC"
printf "${GREEN}Passed:${NC} %d\n" "$pass"
printf "${RED}Failed:${NC} %d\n" "$fail"

if [ "$fail" -gt 0 ]; then
  printf "\nFailed stubs:\n"
  for t in "${failed_tests[@]}"; do
    printf "  - %s\n" "$t"
  done
  exit 1
fi

printf "\n${GREEN}All %d AC stubs passed; живой замер — именованный шаг релизного ритуала (ADR-0027 Решение 1), гейтом не исполняется.${NC}\n" "$pass"
exit 0
