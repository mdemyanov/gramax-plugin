#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-083-openapi-showschemas-showinfo.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-083 (FR-169).
# Дизайн: кластер A, строка FR-169 — блок «OpenAPI» blocks.md пополняется
#   атрибутами showSchemas и showInfo тега <openapi/>; формат спецификации —
#   YAML или JSON (источник RES-007 §2; engine-проб не проводился —
#   пометка источника обязательна по FR-175-механизму).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   showSchemas/showInfo в blocks.md отсутствуют.
# Уровень: integration.
# Замечание: явная фраза «YAML или JSON» дизайн считает частично закрытой
#   существующей строкой «src (путь к YAML/JSON)» — отдельного ассерта на неё
#   нет (чтобы не дублировать уже зелёное состояние); Dev дополняет явной
#   фразой по дизайну, ревьюер сверяет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"

assert_grep "$BLOCKS_MD" 'showSchemas' \
  "AC-083 — blocks.md должен документировать атрибут showSchemas тега <openapi/> (красный на a59db10 — атрибута нет)"
assert_grep "$BLOCKS_MD" 'showInfo' \
  "AC-083 — blocks.md должен документировать атрибут showInfo тега <openapi/> (красный на a59db10)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-083: AC-083 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-083: AC-083 — showSchemas/showInfo задокументированы в разделе OpenAPI"
