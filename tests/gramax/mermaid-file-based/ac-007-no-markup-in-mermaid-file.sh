#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-007-no-markup-in-mermaid-file.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md (Решение 4)
# AC coverage:
#   AC-007 → .mermaid-файл не содержит Gramax XML-разметки (<mermaid>) или fenced block
#             Только чистый DSL, без обёрток.
#
# TDD stub: ПАДАЕТ пока Dev не реализует корректную запись DSL в файл.
# После реализации: .mermaid-файл содержит только DSL (flowchart TB ...), без обёрток.
#
# Уровень: smoke (негативная grep-проверка на запрещённые паттерны)
# Boundary: проверяем и XML-обёртку, и fenced block (оба формата запрещены)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# --- Setup ---
mkdir -p "$TMPDIR_TEST/docs/auth"
DIAGRAM_FILE="$TMPDIR_TEST/docs/auth/overview-auth-flow.mermaid"

# --- AC-007: файл не содержит Gramax XML-разметки (только чистый DSL) ---
echo "TODO: AC-007 — .mermaid-файл не должен содержать <mermaid> или \`\`\`mermaid обёртку" >&2
echo "  Ожидается: ! grep -qE '^(<mermaid>|\`\`\`mermaid)' $DIAGRAM_FILE" >&2

# Файл не существует — тест ПАДАЕТ на assert_file_exists
assert_file_exists "$DIAGRAM_FILE" \
  "AC-007: .mermaid-файл должен существовать (prerequisite от AC-001)"

if [ -f "$DIAGRAM_FILE" ]; then
  # Запрещённые паттерны в начале строки
  assert_no_grep_regex "$DIAGRAM_FILE" '^<mermaid>' \
    "AC-007: .mermaid-файл не должен содержать XML-обёртку <mermaid>"

  assert_no_grep_regex "$DIAGRAM_FILE" '^```mermaid' \
    "AC-007: .mermaid-файл не должен содержать fenced block \`\`\`mermaid"

  assert_no_grep_regex "$DIAGRAM_FILE" '^</mermaid>' \
    "AC-007: .mermaid-файл не должен содержать закрывающий тег </mermaid>"
fi

# --- Negative fixture: dirty-diagram-with-markup.mermaid ДОЛЖЕН нарушать AC-007 ---
# Это валидирует, что наш тест умеет ловить нарушения
DIRTY_FIXTURE="$SCRIPT_DIR/fixtures/dirty-diagram-with-markup.mermaid"
assert_file_exists "$DIRTY_FIXTURE" \
  "AC-007 negative fixture: dirty-diagram-with-markup.mermaid должен существовать"

if [ -f "$DIRTY_FIXTURE" ]; then
  # Dirty fixture СОДЕРЖИТ запрещённый паттерн — проверяем что он действительно там есть
  if ! grep -qE '^<mermaid>' "$DIRTY_FIXTURE" 2>/dev/null; then
    echo "  FAIL: AC-007 negative fixture санити: dirty fixture должен содержать <mermaid>" >&2
    FAIL=$((FAIL + 1))
  fi
fi

# --- Positive fixture: expected-diagram.mermaid НЕ должен содержать обёртки ---
CLEAN_FIXTURE="$SCRIPT_DIR/fixtures/expected-diagram.mermaid"
if [ -f "$CLEAN_FIXTURE" ]; then
  assert_no_grep_regex "$CLEAN_FIXTURE" '^<mermaid>' \
    "AC-007 positive fixture: expected-diagram.mermaid не содержит XML-обёртку"
  assert_no_grep_regex "$CLEAN_FIXTURE" '^```mermaid' \
    "AC-007 positive fixture: expected-diagram.mermaid не содержит fenced block"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-007-no-markup-in-mermaid-file: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-007-no-markup-in-mermaid-file: .mermaid-файл содержит только чистый DSL"
