#!/usr/bin/env bash
# tests/gramax/render-quality/run.sh
# Агрегатор сюиты render-quality — дом-паттерн tests/gramax/render-linter/run.sh; состав
# фиксирован дизайном docs/40-architecture/2026-11-21-playwright-render-quality-design.md,
# Решение 7 («Состав run.sh — контракт раннера»):
#   1) офлайн-стабы ac-*.sh (цикл по glob, свод, rc «хоть один красный»);
#   2) живой прогон прибора bash scripts/render-quality/probe.sh с дефолтными путями
#      (конфиг цели scripts/render-quality/render-target.local.json, фикстуры сюиты,
#      отчёт в results/); rc прибора — вход агрегата. На непрогретой машине живой прогон
#      даёт именованный отказ -> сюита красная -> --full красный (D8: отказ, а не
#      «зелёный без прогона»).
# Подключается к scripts/check-gramax.sh шагом 18 (--full only) ТОЛЬКО после позеленения
# по TDD-цепочке qa-author -> dev -> qa-runner (FR-194, AC-113). В --fast сюиты нет (NFR-078).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$SCRIPT_DIR" || exit 1

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

printf "${YELLOW}Running %d AC stubs from %s${NC}\n\n" "${#tests[@]}" "$SCRIPT_DIR"

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
fi

# --- Живой прогон прибора (дизайн, Решение 7, пункт 2) ---
printf "\n%b==> live probe: bash scripts/render-quality/probe.sh (default paths)%b\n" "$YELLOW" "$NC"
live_rc=0
if [ -f "$ROOT/scripts/render-quality/probe.sh" ]; then
  bash "$ROOT/scripts/render-quality/probe.sh" || live_rc=$?
  if [ "$live_rc" -eq 0 ]; then
    printf '%b\n' "${GREEN}OK: live probe green${NC}"
  else
    printf '%b\n' "${RED}FAIL: live probe rc=${live_rc} (rc=1 — расхождения, rc=2 — именованный отказ окружения; D8)${NC}"
  fi
else
  live_rc=2
  printf '%b\n' "${RED}FAIL: live probe — вход scripts/render-quality/probe.sh отсутствует (каркас прибора не реализован; дизайн, Решение 5)${NC}"
fi

if [ "$fail" -gt 0 ] || [ "$live_rc" -ne 0 ]; then
  exit 1
fi

printf "\n${GREEN}All %d AC stubs passed; live probe green.${NC}\n" "$pass"
exit 0
