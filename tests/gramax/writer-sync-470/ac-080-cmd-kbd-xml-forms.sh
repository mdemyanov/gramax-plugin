#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-080-cmd-kbd-xml-forms.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-080 (FR-166).
# Дизайн: кластер A, строка FR-166 — XML-формы UI-токенов как канон для
#   syntax: XML: <cmd text="…" icon="…" color="…"/> (color — новое знание),
#   <kbd text="…"/>, <alfa/>, <beta/> (engine: cmd.ts:3-10, kbd.ts:3-8,
#   alfaBeta.ts:3-9). Скобочные формы сохраняются валидными (препарсер
#   MdParser.ts:251-263); парность [color:…]…[/color]; legacy <kbd>…</kbd> —
#   короткая пометка «читается движком».
# Природа: КРАСНАЯ на момент создания (по AC: XML-форм нет). Красный на
#   a59db10 (2026-11-18): writer знает только скобочные формы.
# Уровень: integration.
# Регрессия (NFR-071, зелёная часть ассерта): скобочная форма [cmd: уже
#   существует в blocks.md и обязана ПЕРЕЖИТЬ rewrite — зелёный сегодня,
#   защищает аддитивность при вставке XML-раздела.
# NFR-072: selfClosingTags += cmd, kbd, alfa, beta (XML-формы; legacy парная
#   HTML-форма <kbd>…</kbd> в контракт не входит — один тег не может быть в
#   двух списках, канон — self-closing).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"
TAGS_JSON="$ROOT/plugins/gramax/gramax-tags.json"

assert_grep "$BLOCKS_MD" '<cmd text=' \
  "AC-080 — blocks.md должен документировать XML-форму <cmd text=\"…\" icon=\"…\" color=\"…\"/> (красный на a59db10 — XML-форм нет)"
assert_grep "$BLOCKS_MD" '<kbd text=' \
  "AC-080 — blocks.md должен документировать XML-форму <kbd text=\"…\"/>"
assert_grep "$BLOCKS_MD" '[cmd:' \
  "AC-080/NFR-071 — скобочная форма [cmd:Label] остаётся валидной и должна ПЕРЕЖИТЬ rewrite раздела UI-токенов (регрессия; зелёная на a59db10)"

MISSING_SC=$(tags_contract_missing "$TAGS_JSON" selfClosingTags cmd kbd alfa beta)
if [ -n "$MISSING_SC" ]; then
  echo "  FAIL: NFR-072 — selfClosingTags gramax-tags.json не содержит: $MISSING_SC (XML-формы FR-166, одним изменением с writer; красный на a59db10)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-080: AC-080 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-080: AC-080 — XML-формы cmd/kbd задокументированы, скобочные сохранены; NFR-072: cmd/kbd/alfa/beta в selfClosingTags"
