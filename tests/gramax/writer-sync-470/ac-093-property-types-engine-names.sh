#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-093-property-types-engine-names.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-093 (FR-179).
# Дизайн: кластер B, строка FR-179 + Q1в — «Property-определение» переписывается
#   по именам движка: type из шести — Flag, Enum, Many, Text, Numeric, Date
#   (models/index.ts:43-53; служебный BlockMd не подходит для статей);
#   опция options.docportalVisible: true (models/index.ts:9-11); id опционален,
#   без него идентификатор — name; значения в frontmatter пишутся по id
#   (объектная форма {- id, value} — канон сериализации, changeProperty.ts:26-30);
#   «свойство нельзя переименовать» — docs-пометка. Прежнее Enum|String — строка
#   расхождения «типа String в движке нет», не молчаливая замена (NFR-071,
#   факт 18 — до этого проба engine-вердикта не было).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   doc-root-schema.md описывает Enum|String; имён Flag/Many/Text/Numeric/Date
#   и docportalVisible нет.
# Уровень: integration.
# Регрессия: Enum — зелёный на a59db10 (переживает rewrite, входит в шестёрку).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SCHEMA_MD="$ROOT/plugins/gramax/skills/writer/references/doc-root-schema.md"

assert_grep "$SCHEMA_MD" 'docportalVisible' \
  "AC-093 — опция options.docportalVisible: true обязана присутствовать (engine: models/index.ts:9-11; красный на a59db10)"
assert_grep_word "$SCHEMA_MD" 'Flag' \
  "AC-093 — имя типа движка Flag (красный на a59db10 — справочник описывает Enum|String)"
assert_grep_word "$SCHEMA_MD" 'Numeric' \
  "AC-093 — имя типа движка Numeric (красный на a59db10)"
assert_grep_word "$SCHEMA_MD" 'Many' \
  "FR-179 — тип Many из шестёрки движка (красный на a59db10 — имён движка нет)"
assert_grep_word "$SCHEMA_MD" 'Text' \
  "FR-179 — тип Text из шестёрки движка (красный на a59db10)"
assert_grep_word "$SCHEMA_MD" 'Date' \
  "FR-179 — тип Date из шестёрки движка (красный на a59db10; значения frontmatter — ISO 8601, docs-пометка)"
assert_grep_word "$SCHEMA_MD" 'Enum' \
  "FR-179 — Enum входит в шестёрку и обязан ПЕРЕЖИТЬ rewrite (регрессия; зелёная на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-093: AC-093 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-093: AC-093 — типы свойств по именам движка (Flag/Many/Text/Numeric/Date + docportalVisible), Enum сохранён"
