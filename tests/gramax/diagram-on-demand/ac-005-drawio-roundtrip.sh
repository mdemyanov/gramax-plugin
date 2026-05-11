#!/usr/bin/env bash
# AC-005: drawio LLM-XML → drawio_convert.py → .svg с embedded content= атрибутом
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-004, FR-002, FR-009)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 4-5: атомарная запись и drawio_convert.py)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-004 из spec: drawio путь создаёт .drawio и .svg, .svg содержит content= атрибут
#
# Тест вызывает drawio_convert.py напрямую с минимальным валидным mxfile XML.
# LLM-генерацию XML не симулируем — передаём минимально валидный mxfile.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

CONVERT_SCRIPT="$ROOT/plugins/gramax/scripts/drawio_convert.py"

# --- Test 1: drawio_convert.py существует ---
assert_file_exists "$CONVERT_SCRIPT" "drawio_convert.py должен существовать"

# Минимальный валидный mxfile XML
MINIMAL_MXFILE='<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" version="24.3.1">
  <diagram id="test-diagram" name="Page-1">
    <mxGraphModel pageWidth="800" pageHeight="600">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="2" value="API" style="rounded=1;" vertex="1" parent="1">
          <mxGeometry x="100" y="100" width="120" height="60" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>'

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

DRAWIO_FILE="$TMPDIR_TEST/deploy.drawio"
SVG_FILE="$TMPDIR_TEST/deploy.svg"

# Записать .drawio fixture
printf '%s' "$MINIMAL_MXFILE" > "$DRAWIO_FILE"

# --- Test 2: drawio_convert.py завершается с exit 0 на валидном input ---
python3 "$CONVERT_SCRIPT" "$DRAWIO_FILE" "$SVG_FILE"
exit_code=$?
assert_exit_code "$exit_code" "0" "drawio_convert.py должен завершиться с exit 0 на валидном mxfile"

# --- Test 3: .svg файл создан ---
assert_file_exists "$SVG_FILE" "drawio_convert.py должен создать .svg файл"

# --- Test 4: .svg содержит атрибут content= (embedded XML) ---
assert_grep "$SVG_FILE" 'content=' \
  "SVG должен содержать атрибут content= с embedded drawio XML (AC-004: grep -c 'content=' возвращает 1)"

# --- Test 5: .svg является валидным SVG (имеет тег <svg>) ---
assert_grep "$SVG_FILE" '<svg' "SVG файл должен содержать тег <svg>"

# --- Test 6: .drawio файл также существует (оба файла нужны по AC-004) ---
assert_file_exists "$DRAWIO_FILE" ".drawio исходник должен оставаться после конвертации"

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-005-drawio-roundtrip — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-005-drawio-roundtrip"
