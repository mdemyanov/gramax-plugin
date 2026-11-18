#!/usr/bin/env bash
# tests/gramax/export-skill/ac-044-portal-template-placement.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-044 (FR-135).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»,
#   хук AC-042…AC-044: грейпы `assets/pdf`, `assets/word`.
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: предмет проверки plugins/gramax/skills/export/SKILL.md
#   отсутствует. Контракт — спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/export/SKILL.md"

# Гейт существования — до контентных грейпов: пока предмета нет, падение обязано
# называть ровно одну причину (навык не создан).
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-044: SKILL.md навыка export отсутствует ($SKILL_MD) — guidance placement шаблонов не создан (красная причина AC-044)"
  exit 1
fi

# AC-044, литеральные грейпы требования: обе ветки placement шаблонов на портале
# (BR-007: пути фиксируются только в объёме RES-007).
assert_grep "$SKILL_MD" 'assets/pdf' \
  "AC-044 — SKILL.md обязан называть ветку placement assets/pdf (FR-135)"
assert_grep "$SKILL_MD" 'assets/word' \
  "AC-044 — SKILL.md обязан называть ветку placement assets/word (FR-135)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-044: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-044: placement шаблонов на портале (assets/pdf, assets/word) присутствует в SKILL.md"
