#!/usr/bin/env bash
# tests/gramax/link-form-resolver/run.sh
# Aggregator: runs all ac-*.sh, prints summary, returns non-zero if any failed.
# Смешанное стартовое состояние ожидаемо (см. README.md → таблица «Стартовое состояние»):
# часть тестов КРАСНАЯ (новая функциональность инференса ещё не реализована), часть —
# ЗЕЛЁНАЯ regression guard (инвариант NFR-001, уже верен и обязан остаться верным).
# Suite НЕ подключён к scripts/check.sh — подключение делает Dev тем же шагом, что
# закрывает FR-082 (см. README.md).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

printf "${YELLOW}Running %d AC tests from %s${NC}\n\n" "${#tests[@]}" "$SCRIPT_DIR"

for t in "${tests[@]}"; do
  if bash "$t"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failed_tests+=("$t")
  fi
done

printf "\n%b━━━ Summary ━━━%b\n" "$YELLOW" "$NC"
printf "${GREEN}Passed:${NC} %d\n" "$pass"
printf "${RED}Failed:${NC} %d\n" "$fail"

if [ "$fail" -gt 0 ]; then
  printf "\nFailed tests:\n"
  for t in "${failed_tests[@]}"; do
    printf "  - %s\n" "$t"
  done
  exit 1
fi

printf "\n${GREEN}All %d AC tests passed.${NC}\n" "$pass"
exit 0
