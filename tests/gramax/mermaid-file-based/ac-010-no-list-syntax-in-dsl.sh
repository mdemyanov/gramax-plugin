#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-010-no-list-syntax-in-dsl.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md (Решение 4)
# AC coverage:
#   AC-010 → DSL в .mermaid-файле не содержит паттерн "число. пробел" (list-syntax conflict)
#             Паттерн: [0-9]\. (число+точка+пробел) в тексте нод → ошибка парсера Mermaid
#
# TDD stub: ПАДАЕТ пока Dev не реализует checklist-проверку перед записью файла.
# После реализации: DSL записывается в файл уже после самопроверки по checklist.
#
# Уровень: smoke (grep-проверка на запрещённый паттерн)
# Boundary: паттерн "1. " в тексте ноды vs допустимые "1.Текст" и "① Текст"

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# list-syntax конфликт: цифра + точка + пробел в тексте ноды
LIST_SYNTAX_REGEX='[0-9]+\. '

# --- Setup ---
mkdir -p "$TMPDIR_TEST/docs/auth"
DIAGRAM_FILE="$TMPDIR_TEST/docs/auth/overview-auth-flow.mermaid"

# --- AC-010: созданный .mermaid-файл не содержит list-syntax паттерн ---
echo "TODO: AC-010 — DSL в .mermaid-файле не должен содержать паттерн '1. ' (list-syntax)" >&2
echo "  Ожидается: ! grep -qE '$LIST_SYNTAX_REGEX' $DIAGRAM_FILE" >&2

# Файл не существует — тест ПАДАЕТ на assert_file_exists
assert_file_exists "$DIAGRAM_FILE" \
  "AC-010: .mermaid-файл должен существовать (prerequisite от AC-001)"

if [ -f "$DIAGRAM_FILE" ]; then
  assert_no_grep_regex "$DIAGRAM_FILE" "$LIST_SYNTAX_REGEX" \
    "AC-010: DSL не должен содержать паттерн 'число. пробел' (list-syntax конфликт)"
fi

# --- Negative fixture: diagram-with-list-syntax.mermaid СОДЕРЖИТ нарушение ---
# Валидирует, что наш тест умеет обнаруживать нарушение
DIRTY_FIXTURE="$SCRIPT_DIR/fixtures/diagram-with-list-syntax.mermaid"
assert_file_exists "$DIRTY_FIXTURE" \
  "AC-010 negative fixture: diagram-with-list-syntax.mermaid должен существовать"

if [ -f "$DIRTY_FIXTURE" ]; then
  # Dirty fixture ДОЛЖЕН содержать запрещённый паттерн — санити-проверка fixture'а
  if ! grep -qE "$LIST_SYNTAX_REGEX" "$DIRTY_FIXTURE" 2>/dev/null; then
    echo "  FAIL: AC-010 negative fixture санити: fixture должен содержать паттерн '1. '" >&2
    FAIL=$((FAIL + 1))
  fi
fi

# --- Positive fixture: expected-diagram.mermaid НЕ содержит list-syntax ---
CLEAN_FIXTURE="$SCRIPT_DIR/fixtures/expected-diagram.mermaid"
if [ -f "$CLEAN_FIXTURE" ]; then
  assert_no_grep_regex "$CLEAN_FIXTURE" "$LIST_SYNTAX_REGEX" \
    "AC-010 positive fixture: expected-diagram.mermaid не содержит list-syntax паттерн"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-010-no-list-syntax-in-dsl: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-010-no-list-syntax-in-dsl: DSL не содержит list-syntax конфликт"
