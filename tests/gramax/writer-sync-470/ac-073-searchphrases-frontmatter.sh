#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-073-searchphrases-frontmatter.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-073 (FR-161).
# Дизайн: docs/40-architecture/2026-11-18-writer-sync-design.md, кластер A, строка FR-161:
#   SKILL.md → секция «Frontmatter», новая таблица «Дополнительные ключи», строка
#   `searchPhrases` (эффект — подъём статьи в поиске; регистр неважен, срабатывание
#   по части слова; engine: KeyPhraseArticleSearcher.ts:27, Item.ts:42).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18): ключ
#   `searchPhrases` нигде в дереве writer не упомянут — writer 4.6.0 его не знает.
# Уровень: integration (grep по дереву навыка; контракт с QA-author дизайна).
# Замечание к букве AC-073: формула требования пропускает ЛЮБОЙ файл
#   (SKILL.md OR references/*.md); этот stub сильнее — по раскладке дизайна
#   (таблица FR → файл) `searchPhrases` живёт в SKILL.md, не в references.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_grep "$SKILL_MD" 'searchPhrases' \
  "AC-073 — SKILL.md должен документировать frontmatter-ключ searchPhrases (FR-161: таблица «Дополнительные ключи» секции Frontmatter; красный на a59db10 — ключа нет нигде в writer)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-073: AC-073 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-073: AC-073 — searchPhrases задокументирован в SKILL.md"
