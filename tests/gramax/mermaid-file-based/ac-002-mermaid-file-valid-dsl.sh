#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-002-mermaid-file-valid-dsl.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md
# AC coverage:
#   AC-002 → первая строка .mermaid-файла — один из 8 поддерживаемых типов Gramax
#
# TDD stub: ПАДАЕТ пока Dev не реализует file-based workflow.
# После реализации: созданный .mermaid-файл начинается с валидного типа диаграммы.
#
# Уровень: smoke (grep на первую строку файла)
# Поддерживаемые типы: flowchart, sequenceDiagram, gantt, classDiagram,
#                      stateDiagram-v2, erDiagram, pie, mindmap

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

SUPPORTED_TYPES_REGEX="^(flowchart|sequenceDiagram|gantt|classDiagram|stateDiagram-v2|erDiagram|pie|mindmap)"

# --- Setup: после реализации skill создаст этот файл ---
DIAGRAM_FILE="$TMPDIR_TEST/docs/auth/overview-auth-flow.mermaid"
mkdir -p "$TMPDIR_TEST/docs/auth"

# TODO: здесь skill должен был уже создать файл после вызова (AC-001).
# Проверяем существующую fixture как эталон корректного DSL.
echo "TODO: AC-002 — skill должен записать в .mermaid-файл DSL, начинающийся с типа диаграммы" >&2
echo "  Ожидается: head -1 $DIAGRAM_FILE | grep -qE '$SUPPORTED_TYPES_REGEX'" >&2

# Файл не существует — тест ПАДАЕТ на assert_file_exists
assert_file_exists "$DIAGRAM_FILE" \
  "AC-002: .mermaid-файл должен существовать (prerequisite от AC-001)"

if [ -f "$DIAGRAM_FILE" ]; then
  FIRST_LINE="$(head -1 "$DIAGRAM_FILE")"
  if ! echo "$FIRST_LINE" | grep -qE "$SUPPORTED_TYPES_REGEX"; then
    echo "  FAIL: AC-002 — первая строка '$FIRST_LINE' не соответствует паттерну поддерживаемых типов" >&2
    echo "  Поддерживаемые: flowchart, sequenceDiagram, gantt, classDiagram, stateDiagram-v2, erDiagram, pie, mindmap" >&2
    FAIL=$((FAIL + 1))
  fi
fi

# --- Boundary: fixtures/expected-diagram.mermaid как эталон корректного формата ---
# Этот тест валидирует сам fixture (должен ПРОХОДИТЬ уже сейчас)
FIXTURE="$SCRIPT_DIR/fixtures/expected-diagram.mermaid"
assert_file_exists "$FIXTURE" \
  "AC-002 fixture: expected-diagram.mermaid должен существовать для сравнения"

if [ -f "$FIXTURE" ]; then
  FIXTURE_FIRST="$(head -1 "$FIXTURE")"
  assert_grep_regex "$FIXTURE" "$SUPPORTED_TYPES_REGEX" \
    "AC-002 fixture sanity: expected-diagram.mermaid начинается с поддерживаемого типа"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-002-mermaid-file-valid-dsl: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-002-mermaid-file-valid-dsl: .mermaid-файл начинается с поддерживаемого типа диаграммы"
