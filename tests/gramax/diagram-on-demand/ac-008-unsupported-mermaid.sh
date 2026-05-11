#!/usr/bin/env bash
# AC-008: gitGraph/journey/requirementDiagram/C4Context → [WARN] с подсказкой, файлы не создаются
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-003, FR-005)
# ADR: n/a (логика skill-промпта)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-003 из spec: неподдерживаемый mermaid-тип → [WARN] в stdout, файлы не создаются, exit 0
#
# Тест проверяет bash-скрипт валидации типа диаграммы.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

VALIDATE_SCRIPT="$ROOT/plugins/gramax/scripts/validate_diagram_type.sh"

# --- Test 1: скрипт существует ---
assert_file_exists "$VALIDATE_SCRIPT" "validate_diagram_type.sh должен существовать"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# Неподдерживаемые типы из spec FR-005:
UNSUPPORTED_TYPES="gitGraph journey requirementDiagram C4Context"

for diagram_type in $UNSUPPORTED_TYPES; do
  # Act: вызов валидатора
  stdout_output=$(bash "$VALIDATE_SCRIPT" "$diagram_type" 2>/dev/null)
  actual_exit=$?

  # Assert: exit code 0 (предупреждение, не ошибка — spec: Exit code 0)
  assert_exit_code "$actual_exit" "0" \
    "validate_diagram_type.sh должен вернуть exit 0 для '$diagram_type' (предупреждение, не ошибка)"

  # Assert: [WARN] в stdout с именем типа
  assert_grep_stdout "$stdout_output" "[WARN]" \
    "stdout должен содержать [WARN] для неподдерживаемого типа '$diagram_type'"
  assert_grep_stdout "$stdout_output" "$diagram_type" \
    "stdout должен называть неподдерживаемый тип '$diagram_type'"

  # Assert: рекомендация альтернативы (flowchart или drawio)
  if ! echo "$stdout_output" | grep -qF "flowchart" && ! echo "$stdout_output" | grep -qF "drawio"; then
    echo "FAIL: stdout должен предлагать 'flowchart' или 'drawio' как альтернативу для '$diagram_type'" >&2
    FAIL=$((FAIL + 1))
  fi
done

# Поддерживаемые типы НЕ должны вызывать [WARN]:
SUPPORTED_TYPES="flowchart sequenceDiagram gantt classDiagram stateDiagram-v2 erDiagram pie mindmap"
for diagram_type in $SUPPORTED_TYPES; do
  stdout_output=$(bash "$VALIDATE_SCRIPT" "$diagram_type" 2>/dev/null)
  actual_exit=$?
  assert_exit_code "$actual_exit" "0" \
    "validate_diagram_type.sh должен вернуть exit 0 для поддерживаемого типа '$diagram_type'"
  assert_not_grep_stdout "$stdout_output" "[WARN]" \
    "поддерживаемый тип '$diagram_type' не должен вызывать [WARN]"
done

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-008-unsupported-mermaid — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-008-unsupported-mermaid"
