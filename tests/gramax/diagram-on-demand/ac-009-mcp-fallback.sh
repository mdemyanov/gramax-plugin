#!/usr/bin/env bash
# AC-009: MCP drawio недоступен → .drawio сохраняется, .svg отсутствует, stderr [ERROR], exit 1
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-009, FR-011)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 4: атомарная запись + ошибка конвертации)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-009 из spec: MCP drawio недоступен (DIAGRAM_DRAWIO_MCP=disabled) →
#     - .drawio файл создан
#     - .svg файл НЕ создан
#     - stderr содержит [ERROR] с командой ручной конвертации
#     - exit code = 1

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SAVE_FLOW_SCRIPT="$ROOT/plugins/gramax/scripts/save_diagram.sh"

assert_file_exists "$SAVE_FLOW_SCRIPT" "save_diagram.sh должен существовать"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# Arrange: минимальный валидный mxfile XML
MINIMAL_MXFILE='<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" version="24.3.1">
  <diagram id="test" name="Page-1">
    <mxGraphModel pageWidth="800" pageHeight="600">
      <root><mxCell id="0"/><mxCell id="1" parent="0"/></root>
    </mxGraphModel>
  </diagram>
</mxfile>'

TARGET_DRAWIO="$TMPDIR_TEST/deploy.drawio"
TARGET_SVG="$TMPDIR_TEST/deploy.svg"

# Act: вызов save_diagram.sh с DIAGRAM_DRAWIO_MCP=disabled
stderr_output=$(
  DIAGRAM_DRAWIO_MCP=disabled \
  bash "$SAVE_FLOW_SCRIPT" \
    --xml "$MINIMAL_MXFILE" \
    --output-drawio "$TARGET_DRAWIO" \
    --output-svg "$TARGET_SVG" \
  2>&1 >/dev/null
)
actual_exit=$?

# Assert: exit code = 1
assert_exit_code "$actual_exit" "1" \
  "save_diagram.sh должен вернуть exit 1 при DIAGRAM_DRAWIO_MCP=disabled"

# Assert: .drawio создан
assert_file_exists "$TARGET_DRAWIO" \
  ".drawio должен быть сохранён даже при недоступном MCP (FR-011, AC-009)"

# Assert: .svg НЕ создан
assert_file_not_exists "$TARGET_SVG" \
  ".svg НЕ должен создаваться при недоступном MCP drawio"

# Assert: stderr содержит [ERROR] и команду ручной конвертации
assert_grep_stdout "$stderr_output" "[ERROR]" \
  "stderr должен содержать [ERROR] при недоступном MCP"
assert_grep_stdout "$stderr_output" "drawio_convert.py" \
  "stderr должен содержать команду ручной конвертации через drawio_convert.py"

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-009-mcp-fallback — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-009-mcp-fallback"
