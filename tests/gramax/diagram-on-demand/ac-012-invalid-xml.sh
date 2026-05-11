#!/usr/bin/env bash
# AC-012: невалидный mxfile XML → drawio_convert.py exit != 0, файл не создан
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-012, FR-009)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 4: ошибка конвертации)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-012 из spec: невалидный XML → python3 ET.parse → exit != 0
#   Проверяем drawio_convert.py напрямую: невалидный XML → error + no file
#   Boundary: пустой .drawio, не-XML контент, отсутствует <diagram>, отсутствует <mxGraphModel>
#
# Этот тест НЕ является failing stub в полном смысле:
# drawio_convert.py уже существует, поэтому тесты на его поведение с невалидным XML
# могут сразу работать. Stub-флаг выставлен для тестов, зависящих от save_diagram.sh.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

CONVERT_SCRIPT="$ROOT/plugins/gramax/scripts/drawio_convert.py"

# --- Предварительная проверка: скрипт существует ---
assert_file_exists "$CONVERT_SCRIPT" "drawio_convert.py должен существовать"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# --- Test 1: пустой файл → exit != 0 ---
EMPTY_FILE="$TMPDIR_TEST/empty.drawio"
SVG_EMPTY="$TMPDIR_TEST/empty.svg"
printf '' > "$EMPTY_FILE"

python3 "$CONVERT_SCRIPT" "$EMPTY_FILE" "$SVG_EMPTY" > /dev/null 2>&1
empty_exit=$?
if [ "$empty_exit" -eq 0 ]; then
  echo "FAIL: drawio_convert.py должен вернуть exit != 0 на пустом файле" >&2
  FAIL=$((FAIL + 1))
fi
assert_file_not_exists "$SVG_EMPTY" \
  ".svg не должен создаваться при ошибке конвертации пустого файла (NFR-005)"

# --- Test 2: не-XML контент → exit != 0 ---
INVALID_FILE="$TMPDIR_TEST/invalid.drawio"
SVG_INVALID="$TMPDIR_TEST/invalid.svg"
printf 'this is not xml at all' > "$INVALID_FILE"

python3 "$CONVERT_SCRIPT" "$INVALID_FILE" "$SVG_INVALID" > /dev/null 2>&1
invalid_exit=$?
if [ "$invalid_exit" -eq 0 ]; then
  echo "FAIL: drawio_convert.py должен вернуть exit != 0 на не-XML вводе" >&2
  FAIL=$((FAIL + 1))
fi
assert_file_not_exists "$SVG_INVALID" \
  ".svg не должен создаваться при ошибке парсинга XML"

# --- Test 3: XML без <diagram> элемента → exit != 0 ---
NO_DIAGRAM_FILE="$TMPDIR_TEST/no-diagram.drawio"
SVG_NO_DIAGRAM="$TMPDIR_TEST/no-diagram.svg"
printf '<?xml version="1.0"?><mxfile><wrongtag/></mxfile>' > "$NO_DIAGRAM_FILE"

python3 "$CONVERT_SCRIPT" "$NO_DIAGRAM_FILE" "$SVG_NO_DIAGRAM" > /dev/null 2>&1
no_diagram_exit=$?
if [ "$no_diagram_exit" -eq 0 ]; then
  echo "FAIL: drawio_convert.py должен вернуть exit != 0 если нет <diagram> элемента" >&2
  FAIL=$((FAIL + 1))
fi
assert_file_not_exists "$SVG_NO_DIAGRAM" \
  ".svg не должен создаваться если нет <diagram> элемента"

# --- Test 4: XML без <mxGraphModel> → exit != 0 ---
NO_MODEL_FILE="$TMPDIR_TEST/no-model.drawio"
SVG_NO_MODEL="$TMPDIR_TEST/no-model.svg"
printf '<?xml version="1.0"?><mxfile><diagram id="d1" name="Page-1">no model here</diagram></mxfile>' > "$NO_MODEL_FILE"

python3 "$CONVERT_SCRIPT" "$NO_MODEL_FILE" "$SVG_NO_MODEL" > /dev/null 2>&1
no_model_exit=$?
if [ "$no_model_exit" -eq 0 ]; then
  echo "FAIL: drawio_convert.py должен вернуть exit != 0 если нет <mxGraphModel>" >&2
  FAIL=$((FAIL + 1))
fi
assert_file_not_exists "$SVG_NO_MODEL" \
  ".svg не должен создаваться если нет <mxGraphModel>"

# --- Test 5: AC-012 валидация через python3 ET.parse (контракт из spec) ---
VALID_DRAWIO="$TMPDIR_TEST/valid.drawio"
printf '<?xml version="1.0" encoding="UTF-8"?>
<mxfile host="app.diagrams.net" version="24.3.1">
  <diagram id="test" name="Page-1">
    <mxGraphModel pageWidth="800" pageHeight="600">
      <root><mxCell id="0"/><mxCell id="1" parent="0"/></root>
    </mxGraphModel>
  </diagram>
</mxfile>' > "$VALID_DRAWIO"

python3 -c "import xml.etree.ElementTree as ET; ET.parse('$VALID_DRAWIO')" 2>/dev/null
assert_exit_code "$?" "0" \
  "валидный .drawio должен проходить ET.parse без ошибок (AC-012 из spec)"

# Невалидный файл должен проваливать ET.parse
python3 -c "import xml.etree.ElementTree as ET; ET.parse('$INVALID_FILE')" > /dev/null 2>&1
et_exit=$?
if [ "$et_exit" -eq 0 ]; then
  echo "FAIL: невалидный XML должен проваливать ET.parse (exit != 0)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-012-invalid-xml — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-012-invalid-xml"
