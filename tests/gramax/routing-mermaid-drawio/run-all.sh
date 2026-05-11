#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/run-all.sh
# Aggregator: runs all ac-*.sh tests, prints summary, returns non-zero if any failed.
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# ADR: docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md
#
# Usage (from repo root or worktree root):
#   bash tests/gramax/routing-mermaid-drawio/run-all.sh

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
  printf "${RED}No ac-*.sh tests found in %s${NC}\n" "$SCRIPT_DIR"
  exit 2
fi

printf "${YELLOW}Running %d AC tests for routing-mermaid-drawio (gramax 3.0.0)${NC}\n\n" "${#tests[@]}"

for t in "${tests[@]}"; do
  if bash "$t"; then
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
  printf "\n${YELLOW}Note:${NC} these are TDD failing stubs — expected before Dev implements the feature.\n"
  exit "$fail"
fi

printf "\n${GREEN}All %d AC tests passed. Feature is complete.${NC}\n" "$pass"
exit 0
