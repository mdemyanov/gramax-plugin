#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-077-cut-property-inline-property.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-077 (FR-164).
# Дизайн: кластер A, строка FR-164 — новые строки справочника blocks.md:
#   <cut text="…" expanded="true">…</cut> (инлайн-спойлер; блочная форма —
#   legacy-пометка «редактор переписывает при сохранении»; engine: cut.ts:6-21),
#   <property id="…" value="…"/> (привязка вкладок/контента к свойству каталога,
#   механизм подстановки версии; engine: propertyTag.ts:3-8),
#   <inline-property bind="…"/> (значение свойства в тексте; engine:
#   inlineProperty.ts:5-11).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18): ни один
#   из трёх элементов в blocks.md не упомянут.
# Уровень: integration.
# NFR-072 (одним изменением с writer): pairedTags += cut (selfClosing: false,
#   cut.ts:11); selfClosingTags += property, inline-property. SUBSET, не
#   равенство — состояние ADR-0024 (diagramTags, plant-uml/bpmn) не трогается.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"
TAGS_JSON="$ROOT/plugins/gramax/gramax-tags.json"

assert_grep "$BLOCKS_MD" '<cut' \
  "AC-077 — blocks.md должен документировать <cut> (инлайн-скрытый фрагмент, атрибуты text/expanded; красный на a59db10 — элемента нет)"
assert_grep "$BLOCKS_MD" '<property' \
  "AC-077 — blocks.md должен документировать <property/> (id/value, привязка к свойству каталога и подстановка версии)"
assert_grep "$BLOCKS_MD" '<inline-property' \
  "AC-077 — blocks.md должен документировать <inline-property/> (bind — значение свойства в тексте)"

MISSING_SC=$(tags_contract_missing "$TAGS_JSON" selfClosingTags property inline-property)
MISSING_PAIRED=$(tags_contract_missing "$TAGS_JSON" pairedTags cut)
MISSING_TAGS="$MISSING_SC $MISSING_PAIRED"
if [ -n "$(echo "$MISSING_TAGS" | tr -d ' ')" ]; then
  echo "  FAIL: NFR-072 — gramax-tags.json не содержит (selfClosing: ${MISSING_SC:-—}; paired: ${MISSING_PAIRED:-—}) — одним изменением с правками writer; красный на a59db10" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-077: AC-077 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-077: AC-077 — <cut>/<property/>/<inline-property/> в blocks.md; NFR-072: cut/property/inline-property в контракте"
