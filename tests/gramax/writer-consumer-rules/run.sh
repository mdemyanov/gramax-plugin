#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/run.sh
# Aggregator: runs all ac-*.sh, prints summary, returns non-zero if any failed.
# Изначальный красный старт (см. README.md → таблица) закрыт DEV-004: все живые AC
# зелёные. Suite подключён к scripts/check.sh --full, по прецеденту
# tests/gramax/mermaid-adoption/run.sh.
# 2026-08-13: ac-002-cross-catalog-code-workflow-example.sh ретирован (ADR-0017) — см.
# README.md → «Ретировка AC-002». Живых скриптов стало 11, не 12.

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
