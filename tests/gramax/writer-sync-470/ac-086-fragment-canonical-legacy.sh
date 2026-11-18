#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-086-fragment-canonical-legacy.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-086 (FR-172).
# Дизайн: кластер A, строка FR-172 + Q5 — RES-008 вердикт 1 (одно из четырёх
#   переигрываний BR-015): канон — <fragment id="…"/> + каталог
#   .gramax/fragments/; ссылка — <fragment-link id>текст</fragment-link>
#   (engine: реестр getTagElementRenderModels.ts:65-72, fragment.ts:5-30,
#   fragmentLink.ts:4-15, const.ts:6,10-11). Форма <snippet id="…"/> /
#   .gramax/snippets/ — LEGACY-пометка «движок читает, при первой правке
#   мигрирует в fragments/»; Q5: рецепт превентивной массовой миграции в скилл
#   НЕ входит. Раздел «Сниппеты» переименовывается в «Фрагменты».
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   fragment/fragment-link в blocks.md отсутствуют, слова «фрагмент» в
#   SKILL.md нет. Под-ассерт 'legacy' в blocks.md — зелёный от рождения
#   (legacy-раздел формул {%…%}); он защищает legacy-словарь справочника при
#   rewrite, отдельным варденом не считается.
# Уровень: integration.
# NFR-072: selfClosingTags += fragment; pairedTags += fragment-link.
# NFR-071 (регрессия, зелёные на a59db10): snippet ОСТАЁТСЯ в selfClosingTags
#   (валидный legacy-алиас — дизайн «Контракт тегов»: «snippet остаётся в
#   списке»); schemaVersion контракта остаётся 2 (ADR-0024 Решение 3 уже
#   поднял 1→2, смена схемы не нужна).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"
TAGS_JSON="$ROOT/plugins/gramax/gramax-tags.json"

assert_grep "$BLOCKS_MD" '<fragment id=' \
  "AC-086 — канон фрагментов <fragment id=\"…\"/> + .gramax/fragments/ в blocks.md (вердикт 1 RES-008; красный на a59db10 — формы нет)"
assert_grep "$BLOCKS_MD" 'fragment-link' \
  "AC-086 — ссылка на фрагмент <fragment-link id>текст</fragment-link> (красный на a59db10)"
assert_grep_regex_i "$BLOCKS_MD" 'legacy' \
  "AC-086 — legacy-пометка для <snippet>/snippets/ («движок читает, при первой правке мигрирует»; под-ассерт зелёный от рождения — legacy-раздел формул; обязан остаться и после rewrite)"
assert_grep "$SKILL_MD" 'фрагмент' \
  "AC-086 — SKILL.md должен назвать фрагменты (строка таблицы блоков/Guardrails/staging «фрагменты/сниппеты»; красный на a59db10 — слова нет)"

MISSING_SC=$(tags_contract_missing "$TAGS_JSON" selfClosingTags fragment)
MISSING_PAIRED=$(tags_contract_missing "$TAGS_JSON" pairedTags fragment-link)
if [ -n "${MISSING_SC}${MISSING_PAIRED}" ]; then
  echo "  FAIL: NFR-072 — gramax-tags.json: selfClosing без [${MISSING_SC:-—}], paired без [${MISSING_PAIRED:-—}] (одним изменением с writer; красный на a59db10)" >&2
  FAIL=$((FAIL + 1))
fi

# NFR-071: snippet — валидный legacy-алиас, из selfClosingTags не удаляется.
MISSING_SNIPPET=$(tags_contract_missing "$TAGS_JSON" selfClosingTags snippet)
if [ -n "$MISSING_SNIPPET" ]; then
  echo "  FAIL: NFR-071 — snippet исчез из selfClosingTags gramax-tags.json (legacy-алиас обязан остаться — существующие каталоги потребителей продолжают работать)" >&2
  FAIL=$((FAIL + 1))
fi

# NFR-072: schemaVersion остаётся 2 (расширение списков аддитивно; ADR-0024 уже поднял 1→2).
SCHEMA_V=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1],encoding="utf-8")).get("schemaVersion"))' "$TAGS_JSON" 2>/dev/null)
if [ "$SCHEMA_V" != "2" ]; then
  echo "  FAIL: NFR-072 — schemaVersion gramax-tags.json = $SCHEMA_V, ожидается 2 (дизайн: смена схемы не нужна)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-086: AC-086 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-086: AC-086 — канон <fragment>+<fragment-link>, legacy-пометка snippet; контракт: fragment/fragment-link добавлены, snippet и schemaVersion 2 сохранены"
