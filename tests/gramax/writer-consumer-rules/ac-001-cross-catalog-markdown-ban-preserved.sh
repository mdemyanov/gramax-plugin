#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-001-cross-catalog-markdown-ban-preserved.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-001.
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел A —
#   FR-066 (ловушка обратных кавычек) вставляется "рядом со строками 204–208 (тот же
#   ❌/✅-блок)" SKILL.md — та же секция "## Ссылки", где живёт правило, защищаемое этим
#   тестом. Этот тест — регрессионный барьер именно на эту вставку: FR-066 не должен
#   переписать или сместить формулировку запрета markdown-ссылки.
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. Запрет markdown-ссылки для
#   cross-каталожных ссылок существует в SKILL.md с первого коммита плагина (d8eb851,
#   2026-05-08 — см. "Описание" требования) и текстуально совпадает с тем, что 5 внешних
#   проектов сформулировали независимо. Тест не ждёт DEV-004 — он защищает формулировку от
#   порчи при точечной вставке FR-066 в ту же секцию.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_grep_regex_i "$SKILL_MD" 'inline code' \
  "AC-001 — SKILL.md должен продолжать называть inline code способом построения cross-каталожной ссылки"
assert_grep_regex_i "$SKILL_MD" 'не резолвит' \
  "AC-001 — SKILL.md должен продолжать объяснять, что Gramax 'не резолвит' markdown-ссылки между .doc-root.yaml-каталогами"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-001: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-001: запрет markdown-ссылки для cross-каталожных ссылок сохранён (regression guard)"
