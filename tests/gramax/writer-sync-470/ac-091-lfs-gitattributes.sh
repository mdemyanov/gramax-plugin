#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-091-lfs-gitattributes.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-091 (FR-177).
# Дизайн: кластер B, строка FR-177 — doc-root-schema.md «Служебные папки и
#   файловые следы»: .gitattributes рядом с .doc-root.yaml определяет
#   отслеживаемые файлы; ключ lfs {auto, exclude} (перекрёстная ссылка на
#   FR-174; engine: CatalogProps.ts:21, autoLfsAttachments.ts:21-24).
#   SKILL.md → Guardrails: указатели Git LFS входят в перечень «не трогать».
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   lfs/.gitattributes в doc-root-schema.md отсутствуют.
# Уровень: integration.
# Замечание к букве AC-091: формула требования проверяет только
#   doc-root-schema.md; stub сильнее на одно место из таблицы FR → файл
#   (строка LFS-указателей в Guardrails SKILL.md).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SCHEMA_MD="$ROOT/plugins/gramax/skills/writer/references/doc-root-schema.md"
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_grep_regex_i "$SCHEMA_MD" 'lfs' \
  "AC-091 — doc-root-schema.md должен документировать ключ lfs {auto, exclude} (красный на a59db10 — ключа нет)"
assert_grep "$SCHEMA_MD" '.gitattributes' \
  "AC-091 — doc-root-schema.md должен документировать .gitattributes рядом с .doc-root.yaml (красный на a59db10)"
assert_grep_regex_i "$SKILL_MD" 'LFS' \
  "FR-177, таблица FR → файл — SKILL.md Guardrails: указатели Git LFS в перечне «не трогать» (красный на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-091: AC-091 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-091: AC-091 — lfs/.gitattributes в doc-root-schema.md, LFS-указатели в Guardrails SKILL.md"
