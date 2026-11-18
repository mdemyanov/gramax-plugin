#!/usr/bin/env bash
# tests/gramax/writer-sync-470/ac-084-code-block-section.sh
# Требование: docs/30-requirements/2026-11-18-writer-sync-470-requirement.md — AC-084 (FR-170).
# Дизайн: кластер A, строка FR-170 — НОВЫЙ раздел «Блок кода» blocks.md:
#   блок и строка, подсветка по языку; полные имена языков highlight.js в
#   код-блоках; когда содержимое содержит тройные кавычки — обёртка в четыре
#   (источник RES-007 §2 «Блок кода» + §3; docs-пометка).
# Природа: КРАСНАЯ на момент создания. Красный на a59db10 (2026-11-18):
#   выделенного раздела о блоках кода в writer нет.
# Уровень: integration.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BLOCKS_MD="$ROOT/plugins/gramax/skills/writer/references/blocks.md"

assert_grep_regex_i "$BLOCKS_MD" 'блок кода' \
  "AC-084 — blocks.md должен получить выделенный раздел «Блок кода» (красный на a59db10 — раздела нет)"
assert_grep_regex_i "$BLOCKS_MD" 'highlight\.js' \
  "AC-084 — подсветка по полным именам языков highlight.js (красный на a59db10 — не упоминается)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-084: AC-084 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-084: AC-084 — раздел «Блок кода» с highlight.js присутствует"
