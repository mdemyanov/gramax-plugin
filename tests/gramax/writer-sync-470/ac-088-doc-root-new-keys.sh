#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-088-doc-root-new-keys.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-088 (FR-174).
# Дизайн: кластер B, строка FR-174 + Q1 — отсутствующие ключи doc-root-schema.md,
#   ВСЕ engine-верифицированы пробом на пине 48592b36 (пометка «расхождение»
#   не нужна): logo/logo_dark (формы icon:<код>[:<цвет>] и emoji:<символ> —
#   catalogLogoIcon.ts:4-24, CatalogProps.ts:38-39), versions: string[]
#   (CatalogProps.ts:16), relatedLinks (кнопки действия; запись
#   {url, title, icon?, target?} — NavigationLinks.ts:63-71), lfs {auto, exclude}
#   (autoLfsAttachments.ts:21-24), hidden: boolean (CatalogProps.ts:25).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   ни одного из этих ключей в doc-root-schema.md нет; из filter-ключей
#   документирована только непрочитываемая движком форма filterProperties.
# Уровень: integration.
# Regex AC-088 'filterProperty([^i]|$)': множественная форма filterProperties
#   НЕ матчится (после «filterPropert» идёт «i») — справочник вправе упоминать
#   обе формы, но сингулярная (действующий ключ движка, CatalogProps.ts:17)
#   обязана присутствовать; форма filterProperties сохраняется одной строкой
#   как legacy-форма writer с пометкой «движком не читается» (Q1б).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SCHEMA_MD="$ROOT/plugins/gramax/skills/writer/references/doc-root-schema.md"

assert_grep "$SCHEMA_MD" 'logo_dark' \
  "AC-088 — doc-root-schema.md должен документировать logo_dark (Q1д: формы icon:<код>[:<цвет>] / emoji:<символ>; красный на a59db10 — ключа нет)"
assert_grep "$SCHEMA_MD" 'relatedLinks' \
  "AC-088 — doc-root-schema.md должен документировать relatedLinks (кнопки действия каталога, запись {url, title, icon?, target?})"
assert_grep "$SCHEMA_MD" 'versions' \
  "AC-088 — doc-root-schema.md должен документировать versions (массив шаблонов веток/тегов)"
assert_grep "$SCHEMA_MD" 'hidden' \
  "AC-088 — doc-root-schema.md должен документировать hidden (boolean)"
assert_grep_regex "$SCHEMA_MD" 'filterProperty([^i]|$)' \
  "AC-088 — сингулярный действующий ключ filterProperty (одиночный id) обязан присутствовать; множественная форма regex-ом не матчится и одна её недостаточна (красный на a59db10 — только filterProperties)"
assert_grep "$SCHEMA_MD" 'emoji:' \
  "FR-174/Q1д — форма логотипа emoji:<символ> обязана присутствовать (engine-верифицирована; красный на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-088: AC-088 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-088: AC-088 — новые ключи схемы (logo_dark, relatedLinks, versions, hidden, filterProperty, emoji:) в doc-root-schema.md"
