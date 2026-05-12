#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-011-no-inline-phrase-in-skill.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md (Бриф для Dev, п.1 — fallback-диалог)
# AC coverage:
#   AC-011 → fallback-диалог в SKILL.md не содержит фразу «inline DSL, без файла»
#             (устаревший текст mermaid-опции должен быть заменён на file-based описание)
#
# TDD stub: ПАДАЕТ на текущем SKILL.md (v3.0.0), который СОДЕРЖИТ эту фразу.
# После реализации: Dev обновляет fallback-секцию SKILL.md — фраза исчезает.
#
# Уровень: smoke (grep-проверка на наличие устаревшей фразы в файле)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL_MD="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

# --- AC-011: SKILL.md не содержит устаревшую фразу «inline DSL, без файла» ---
assert_file_exists "$SKILL_MD" \
  "AC-011: plugins/gramax/skills/mermaid/SKILL.md должен существовать"

if [ -f "$SKILL_MD" ]; then
  # Текущий SKILL.md (v3.0.0) СОДЕРЖИТ эту фразу — тест ПАДАЕТ
  assert_no_grep "$SKILL_MD" 'inline DSL, без файла' \
    "AC-011: SKILL.md не должен содержать устаревшую фразу 'inline DSL, без файла'"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-011-no-inline-phrase-in-skill: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-011-no-inline-phrase-in-skill: SKILL.md не содержит устаревшую фразу 'inline DSL, без файла'"
