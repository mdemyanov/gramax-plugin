#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/run.sh
# Aggregator: запускает все ac-*.sh тесты, выводит PASS/FAIL по каждому.
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md
#
# Usage (из корня репозитория):
#   bash tests/gramax/mermaid-file-based/run.sh
#
# TDD workflow:
#   - Все тесты RED до реализации Dev (gramax v4.0.0)
#   - После реализации SKILL.md file-based workflow — тесты становятся GREEN

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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
  printf "${RED}No ac-*.sh tests found in %s${NC}\n" "$SCRIPT_DIR" >&2
  exit 2
fi

printf "${YELLOW}Running %d AC tests for mermaid-file-based (gramax v4.0.0)${NC}\n\n" "${#tests[@]}"

for t in "${tests[@]}"; do
  if bash "$SCRIPT_DIR/$t"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    failed_tests+=("$t")
  fi
done

printf "\n${YELLOW}━━━ Summary ━━━${NC}\n"
printf "${GREEN}Passed:${NC} %d\n" "$pass"
printf "${RED}Failed:${NC} %d\n" "$fail"

if [ "$fail" -gt 0 ]; then
  printf "\nFailed tests:\n"
  for t in "${failed_tests[@]}"; do
    printf "  - %s\n" "$t"
  done
  printf "\n${YELLOW}Note:${NC} RED tests are expected before Dev implements mermaid file-based workflow.\n"
  printf "${YELLOW}      Make them GREEN: implement SKILL.md v4.0.0 per ADR-0010.${NC}\n"
  exit "$fail"
fi

printf "\n${GREEN}All %d AC tests passed. mermaid-file-based v4.0.0 is complete.${NC}\n" "$pass"
exit 0
