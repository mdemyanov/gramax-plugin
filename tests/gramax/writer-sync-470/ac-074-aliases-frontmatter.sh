#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-074-aliases-frontmatter.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-074 (FR-162).
# Дизайн: кластер A, строка FR-162 — ДВА места: references/structure.md
#   («Переместить статью»/«Переместить раздел»: шаг «добавь старый путь в aliases,
#   UI-перенос пишет его сам»; engine: aliasAutowrite.ts:31-44) и SKILL.md
#   (строка-указатель в таблице «Дополнительные ключи»).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18): ключ
#   `aliases` нигде в дереве writer не упомянут.
# Уровень: integration.
# Замечание к букве AC-074: формула требования пропускает любой один файл;
#   stub сильнее — оба места из таблицы FR → файл (список путей без .md от корня
#   контента; агент добавляет при ручном переименовании).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"
STRUCTURE_MD="$ROOT/plugins/gramax/skills/writer/references/structure.md"

assert_grep "$STRUCTURE_MD" 'aliases' \
  "AC-074 — structure.md должен получить шаг «добавь старый путь в aliases» в разделах «Переместить статью»/«Переместить раздел» (FR-162; красный на a59db10 — ключа нет нигде в writer)"
assert_grep "$SKILL_MD" 'aliases' \
  "AC-074 — SKILL.md должен получить строку-указатель aliases в таблице «Дополнительные ключи» (FR-162)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-074: AC-074 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-074: AC-074 — aliases задокументирован в structure.md и SKILL.md"
