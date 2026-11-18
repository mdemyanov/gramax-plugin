#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-085-heading-anchors.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-085 (FR-171).
# Дизайн: кластер A, строка FR-171 — НОВЫЙ раздел «Якоря заголовков» blocks.md:
#   суффикс {#имя} на заголовке любого уровня + ссылка на якорь из текста
#   статьи; engine: сериализатор заголовков пишет {#id} (headingFormatter.ts:6).
#   SKILL.md → строка-указатель в «Ссылки» (таблица FR → файл).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   якоря {#…} в writer не упомянуты.
# Уровень: integration.
# Замечание к букве AC-085: формула требования проверяет только blocks.md;
#   stub сильнее на одно место из таблицы FR → файл (строка в «Ссылки» SKILL.md).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_grep "$BLOCKS_MD" '{#' \
  "AC-085 — blocks.md должен документировать якоря заголовков {#имя} и ссылку на якорь (красный на a59db10 — якорей нет)"
assert_grep "$SKILL_MD" '{#' \
  "FR-171, таблица FR → файл — SKILL.md раздел «Ссылки» получает строку-указатель на якоря (красный на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-085: AC-085 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-085: AC-085 — якоря {#имя} задокументированы в blocks.md и SKILL.md"
