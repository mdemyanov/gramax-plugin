#!/usr/bin/env bash
# tests/project/sunset-pattern-in-agents/run.sh
# Покрытие AC для фичи «sunset-паттерн в qa-author/dev промптах».
# Источник: docs/lessons-learned.md 2026-05-11 (sunset diagram-on-demand + diagrams).
#
# TDD: тест падает пока agent-промпты не содержат явный sunset-pattern marker.

set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

FAIL=0
QA_FILE=".claude/plugins/project/agents/qa-author-agent.md"
DEV_FILE=".claude/plugins/project/agents/dev-agent.md"

check_file_exists() {
  local f="$1"
  if [ ! -f "$f" ]; then
    printf "${RED}FAIL${NC}: file missing: %s\n" "$f"
    FAIL=$((FAIL + 1))
    return 1
  fi
}

check_contains() {
  local file="$1" pattern="$2" label="$3"
  if ! grep -qE "$pattern" "$file" 2>/dev/null; then
    printf "${RED}FAIL${NC}: %s — pattern not found in %s: /%s/\n" "$label" "$file" "$pattern"
    FAIL=$((FAIL + 1))
  else
    printf "${GREEN}PASS${NC}: %s — found in %s\n" "$label" "$file"
  fi
}

check_file_exists "$QA_FILE"
check_file_exists "$DEV_FILE"

# AC-1: qa-author-agent.md имеет блок про sunset / удаление skill/script и обязательный AC на orphan references.
check_contains "$QA_FILE" "[Ss]unset" \
  "AC-1a: qa-author mentions sunset"
check_contains "$QA_FILE" "orphan" \
  "AC-1b: qa-author mentions orphan references"
check_contains "$QA_FILE" "grep -rn" \
  "AC-1c: qa-author prescribes 'grep -rn' wide-sweep"

# AC-2: dev-agent.md имеет post-delete wide-sweep grep как обязательный шаг
check_contains "$DEV_FILE" "[Ss]unset|[Уу]даление" \
  "AC-2a: dev mentions sunset/deletion workflow"
check_contains "$DEV_FILE" "orphan|остаточных|остаточные" \
  "AC-2b: dev mentions orphan/residual references"
check_contains "$DEV_FILE" "grep -rn" \
  "AC-2c: dev prescribes 'grep -rn' after delete"

# AC-3: оба упоминают reference на lessons-learned 2026-05-11 (трассируемость)
check_contains "$QA_FILE" "lessons-learned|PR #4|2026-05-11|diagram-on-demand" \
  "AC-3a: qa-author references the lesson source"
check_contains "$DEV_FILE" "lessons-learned|PR #4|2026-05-11|diagram-on-demand" \
  "AC-3b: dev references the lesson source"

echo
if [ "$FAIL" -gt 0 ]; then
  printf "${RED}FAILED: %d assertion(s)${NC}\n" "$FAIL"
  exit 1
fi
printf "${GREEN}All assertions passed.${NC}\n"
exit 0
