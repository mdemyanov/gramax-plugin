#!/usr/bin/env bash
# tests/gramax/render-quality/ac-104-fixtures-catalog.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-104 (FR-187)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 5
#   («Формат фикстур и ожиданий») и «Контракт с QA-author», строка ac-104.
# Проверка (контракт данных прибора): fixtures/ содержит страницу на каждую конструкцию и
# фикстуру-дефект на каждую из 8 строк ERROR-таблицы апстрима (RES-009 §2); каждая
# фикстура-дефект несёт ровно одну дефектную конструкцию; каждая .md имеет пару
# <имя>.expect.json с заполненным tableRow. Соответствие «файл ↔ строка таблицы» — README.
# Цвет при создании: ЗЕЛЁНЫЙ с рождения — данные (фикстуры) сажает сам qa-author;
# варден каталога: ломается, если фикстуру отредактируют вразрез с картой (дизайн:
# «красный до посадки фикстур; зелёный после (данные qa-author)»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

expect_present() { # файл, образец, сообщение
  if ! grep -qF -- "$2" "$1" 2>/dev/null; then
    echo "  FAIL: $3 — образец '$2' не найден в $(basename "$1")" >&2
    FAIL=$((FAIL + 1))
  fi
}

expect_absent() { # файл, образец, сообщение
  if grep -qF -- "$2" "$1" 2>/dev/null; then
    echo "  FAIL: $3 — чужая конструкция '$2' найдена в $(basename "$1") (дефект-фикстура несёт ровно одну конструкцию)" >&2
    FAIL=$((FAIL + 1))
  fi
}

expect_count() { # файл, образец, ожидаемое число вхождений строк, сообщение
  local got
  got=$(grep -cF -- "$2" "$1" 2>/dev/null || true)
  if [ "$got" != "$3" ]; then
    echo "  FAIL: $4 — строк с '$2' в $(basename "$1"): $got, ожидается $3" >&2
    FAIL=$((FAIL + 1))
  fi
}

# --- 1. Все файлы каталога на месте (8 строк ERROR + 2 спорные + 7 контрольных) ---
for name in \
  th-in-table note-inline invalid-utf8 multiple-images unbalanced-pair-tags \
  colgroup-multiline xml-in-html-comment tag-fragment-tail \
  note-in-cell note-in-note \
  control-table control-colgroup-single-line control-note-block control-images \
  control-balanced-tags control-html-comment-text control-utf8; do
  assert_file_exists "$FIXTURES/$name.md" "AC-104: фикстура $name.md"
  assert_file_exists "$FIXTURES/$name.expect.json" "AC-104: ожидание $name.expect.json"
done

# --- 2. tableRow заполнен в каждом expect.json; значения — из карты «файл ↔ строка» ---
# (пары «имя|строка» — без ассоциативных массивов: системный bash 3.2, дом-прецедент)
TABLE_ROW_PAIRS="
th-in-table|ERROR-1
note-inline|ERROR-2
invalid-utf8|ERROR-3
multiple-images|ERROR-4
unbalanced-pair-tags|ERROR-5
colgroup-multiline|ERROR-6
xml-in-html-comment|ERROR-7
tag-fragment-tail|ERROR-8
note-in-cell|WARN-note-in-cell
note-in-note|WARN-note-in-note
"
while IFS='|' read -r name row; do
  [ -z "$name" ] && continue
  assert_grep "$FIXTURES/$name.expect.json" "\"tableRow\": \"$row\"" \
    "AC-104: $name.expect.json — tableRow обязан быть \"$row\""
done <<< "$TABLE_ROW_PAIRS"
for name in control-table control-colgroup-single-line control-note-block control-images \
            control-balanced-tags control-html-comment-text control-utf8; do
  assert_grep "$FIXTURES/$name.expect.json" '"tableRow": "control"' \
    "AC-104: $name.expect.json — tableRow обязан быть \"control\""
done

# --- 3. expect.json — валидный JSON (python3 -I, без импорта из дерева) ---
if command -v python3 > /dev/null 2>&1; then
  for f in "$FIXTURES"/*.expect.json; do
    if ! python3 -I -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8'))" "$f" 2> /dev/null; then
      echo "  FAIL: AC-104 — $(basename "$f") не разбирается как JSON" >&2
      FAIL=$((FAIL + 1))
    fi
  done
else
  echo "  FAIL: AC-104 — python3 не найден, JSON-валидность ожиданий не проверена" >&2
  FAIL=$((FAIL + 1))
fi

# --- 4. Каждая дефект-фикстура несёт РОВНО одну дефектную конструкцию ---
# Присутствие своей конструкции
expect_present "$FIXTURES/th-in-table.md" "<th>" "AC-104: ERROR-1 — <th> обязан присутствовать"
expect_present "$FIXTURES/note-inline.md" "<note type=\"warning\">Инлайновая заметка в одну строку</note>" \
  "AC-104: ERROR-2 — инлайновый однострочный note обязан присутствовать"
expect_present "$FIXTURES/multiple-images.md" "![](izobrazenie-a.png) ![](izobrazenie-b.png)" \
  "AC-104: ERROR-4 — несколько изображений в одной строке обязаны присутствовать"
expect_present "$FIXTURES/unbalanced-pair-tags.md" "<tabs>" "AC-104: ERROR-5 — открытые парные теги обязаны присутствовать"
if [ "$(grep -c '</tabs>' "$FIXTURES/unbalanced-pair-tags.md" 2> /dev/null)" != "0" ] || \
   [ "$(grep -c '</tab>' "$FIXTURES/unbalanced-pair-tags.md" 2> /dev/null)" != "0" ]; then
  echo "  FAIL: AC-104 — unbalanced-pair-tags.md не должен нести закрывающих тегов (баланс нарушен)" >&2
  FAIL=$((FAIL + 1))
fi
expect_present "$FIXTURES/colgroup-multiline.md" "<col style=\"width: 30%\"/>" \
  "AC-104: ERROR-6 — col в многострочном colgroup обязан присутствовать"
if [ "$(grep -c '<colgroup>' "$FIXTURES/colgroup-multiline.md")" -gt 0 ] && \
   [ "$(grep -c '</colgroup>' "$FIXTURES/colgroup-multiline.md")" -gt 0 ] && \
   [ "$(grep -n '<colgroup>' "$FIXTURES/colgroup-multiline.md" | cut -d: -f1)" = \
     "$(grep -n '</colgroup>' "$FIXTURES/colgroup-multiline.md" | cut -d: -f1)" ]; then
  echo "  FAIL: AC-104 — colgroup-multiline.md: colgroup не многострочный (открывающий и закрывающий на одной строке)" >&2
  FAIL=$((FAIL + 1))
fi
expect_present "$FIXTURES/xml-in-html-comment.md" '<!-- Черновик: старая вставка <view src="shema.xml"/> удалена отсюда -->' \
  "AC-104: ERROR-7 — XML-тег внутри HTML-комментария обязан присутствовать"
expect_present "$FIXTURES/tag-fragment-tail.md" 'splay="List"/>' \
  "AC-104: ERROR-8 — обрывок тега с хвостом обязан присутствовать"
# Байтовая фикстура обязана НЕ декодироваться как UTF-8
if python3 -I -c "
import sys
try:
    open(sys.argv[1], 'rb').read().decode('utf-8')
except UnicodeDecodeError:
    sys.exit(1)
sys.exit(0)
" "$FIXTURES/invalid-utf8.md"; then
  echo "  FAIL: AC-104 — invalid-utf8.md обязан быть байтовой фикстурой (не декодируется как UTF-8)" >&2
  FAIL=$((FAIL + 1))
fi
# Спорные severity — конструкции на месте
expect_present "$FIXTURES/note-in-cell.md" "<note type=\"info\">" "AC-104: note-in-cell — блочный note в td обязан присутствовать"
expect_count "$FIXTURES/note-in-note.md" "<note " 2 "AC-104: note-in-note — ровно два note (внешний + вложенный)"

# Отсутствие чужих дефектных конструкций (соответствие «файл ↔ строка» — одна причина на фикстуру)
expect_absent "$FIXTURES/th-in-table.md" "<note" "AC-104: th-in-table"
expect_absent "$FIXTURES/th-in-table.md" "![](" "AC-104: th-in-table"
expect_absent "$FIXTURES/th-in-table.md" "<colgroup" "AC-104: th-in-table"
expect_absent "$FIXTURES/note-inline.md" "<th>" "AC-104: note-inline"
expect_absent "$FIXTURES/note-inline.md" "<colgroup" "AC-104: note-inline"
expect_absent "$FIXTURES/multiple-images.md" "<th>" "AC-104: multiple-images"
expect_absent "$FIXTURES/multiple-images.md" "<note" "AC-104: multiple-images"
expect_absent "$FIXTURES/unbalanced-pair-tags.md" "<th>" "AC-104: unbalanced-pair-tags"
expect_absent "$FIXTURES/unbalanced-pair-tags.md" "<colgroup" "AC-104: unbalanced-pair-tags"
expect_absent "$FIXTURES/colgroup-multiline.md" "<th>" "AC-104: colgroup-multiline"
expect_absent "$FIXTURES/colgroup-multiline.md" "<note" "AC-104: colgroup-multiline"
expect_absent "$FIXTURES/xml-in-html-comment.md" "<th>" "AC-104: xml-in-html-comment"
expect_absent "$FIXTURES/xml-in-html-comment.md" "<note" "AC-104: xml-in-html-comment"
expect_absent "$FIXTURES/tag-fragment-tail.md" "<th>" "AC-104: tag-fragment-tail"
expect_absent "$FIXTURES/tag-fragment-tail.md" "<note" "AC-104: tag-fragment-tail"
expect_absent "$FIXTURES/note-in-cell.md" "<th>" "AC-104: note-in-cell"
expect_absent "$FIXTURES/note-in-cell.md" "<colgroup" "AC-104: note-in-cell"

# --- 5. Контрольные страницы — легальные формы (без дефектных конструкций) ---
for name in control-table control-colgroup-single-line control-note-block control-images \
            control-balanced-tags control-html-comment-text control-utf8; do
  expect_absent "$FIXTURES/$name.md" "<th>" "AC-104: контроль $name без дефектов"
  expect_absent "$FIXTURES/$name.md" "splay=" "AC-104: контроль $name без дефектов"
done
expect_absent "$FIXTURES/control-table.md" "<note" "AC-104: контроль control-table без дефектов"
expect_absent "$FIXTURES/control-images.md" "![](a.png) ![](" "AC-104: контроль control-images — изображения по одному на строку"
if python3 -I -c "
import sys
try:
    open(sys.argv[1], 'rb').read().decode('utf-8')
except UnicodeDecodeError:
    sys.exit(1)
sys.exit(0)
" "$FIXTURES/control-utf8.md"; then
  :
else
  echo "  FAIL: AC-104 — control-utf8.md обязан быть валидным UTF-8" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-104: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-104: каталог фикстур полон (17 .md + 17 expect.json), tableRow по карте, дефект-фикстура = одна конструкция"
