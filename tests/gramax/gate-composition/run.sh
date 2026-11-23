#!/usr/bin/env bash
# tests/gramax/gate-composition/run.sh
# Aggregator: runs all ac-*.sh, prints summary, returns non-zero if any failed.
# Статус: failing stubs (QA-author, до правок Dev) — волна-3, гейты и хвосты гигиены
# (AC-143…AC-147, AC-149, AC-150 требования
# docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md;
# механика — ADR-0027 docs/00-project/adr/0027-full-gate-composition.md).
# Регистрация в scripts/check-gramax.sh --full — задача Dev, последним шагом блока
# (поправка PM к списку ADR-0027: 17 сюит с этой); до регистрации сюита standalone.
# Красный прогон — ожидаемое состояние TDD-цикла: красные ноги каждого стаба
# перечислены в docs/60-implementation/acceptance/2026-11-23-wave3-gates-at-design.md.

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

printf "${YELLOW}Running %d AC stubs from %s${NC}\n\n" "${#tests[@]}" "$SCRIPT_DIR"

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
  printf "\nFailed stubs:\n"
  for t in "${failed_tests[@]}"; do
    printf "  - %s\n" "$t"
  done
  exit 1
fi

printf "\n${GREEN}All %d AC stubs passed.${NC}\n" "$pass"
exit 0
