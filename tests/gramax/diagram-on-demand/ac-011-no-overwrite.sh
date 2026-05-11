#!/usr/bin/env bash
# AC-011: существующий файл → [WARN] в stdout, перезапись не выполняется без --force
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-010, FR-007)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 3: проверка существующего файла)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-010 из spec: файл уже существует → [WARN] с путём, перезапись не выполняется

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SAVE_FLOW_SCRIPT="$ROOT/plugins/gramax/scripts/save_diagram.sh"

assert_file_exists "$SAVE_FLOW_SCRIPT" "save_diagram.sh должен существовать"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# Arrange: уже существующие файлы
MINIMAL_MXFILE='<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" version="24.3.1">
  <diagram id="test" name="Page-1">
    <mxGraphModel pageWidth="800" pageHeight="600">
      <root><mxCell id="0"/><mxCell id="1" parent="0"/></root>
    </mxGraphModel>
  </diagram>
</mxfile>'

TARGET_DRAWIO="$TMPDIR_TEST/existing.drawio"
TARGET_SVG="$TMPDIR_TEST/existing.svg"
ORIGINAL_CONTENT="original drawio content"
printf '%s' "$ORIGINAL_CONTENT" > "$TARGET_DRAWIO"
printf '%s' "original svg" > "$TARGET_SVG"

# Act: вызов без --force (файл уже существует)
stdout_output=$(
  bash "$SAVE_FLOW_SCRIPT" \
    --xml "$MINIMAL_MXFILE" \
    --output-drawio "$TARGET_DRAWIO" \
    --output-svg "$TARGET_SVG" \
  2>/dev/null
)
actual_exit=$?

# Assert: завершение без перезаписи (exit 0 — предупреждение, не ошибка)
assert_exit_code "$actual_exit" "0" \
  "save_diagram.sh без --force должен завершиться с exit 0 (предупреждение)"

# Assert: [WARN] в stdout с путём к файлу
assert_grep_stdout "$stdout_output" "[WARN]" \
  "stdout должен содержать [WARN] при конфликте файла"
assert_grep_stdout "$stdout_output" "existing.drawio" \
  "stdout должен указывать путь к конфликтующему файлу"

# Assert: оригинальный файл не перезаписан
current_content=$(cat "$TARGET_DRAWIO")
assert_eq "$current_content" "$ORIGINAL_CONTENT" \
  ".drawio не должен быть перезаписан без --force"

# --- Test 2: с флагом --force — перезапись разрешена ---
stdout_force=$(
  bash "$SAVE_FLOW_SCRIPT" \
    --xml "$MINIMAL_MXFILE" \
    --output-drawio "$TARGET_DRAWIO" \
    --output-svg "$TARGET_SVG" \
    --force \
  2>/dev/null
)
force_exit=$?
assert_exit_code "$force_exit" "0" \
  "save_diagram.sh с --force должен завершиться с exit 0"
assert_file_exists "$TARGET_DRAWIO" ".drawio должен существовать после --force"
assert_file_exists "$TARGET_SVG" ".svg должен существовать после --force"
# Файл должен содержать новый mxfile, а не оригинальный контент
if grep -qF "$ORIGINAL_CONTENT" "$TARGET_DRAWIO"; then
  echo "FAIL: .drawio должен быть перезаписан при --force" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-011-no-overwrite — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-011-no-overwrite"
