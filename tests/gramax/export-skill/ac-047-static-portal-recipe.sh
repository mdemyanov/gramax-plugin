#!/usr/bin/env bash
# tests/gramax/export-skill/ac-047-static-portal-recipe.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-047 (FR-139).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»,
#   хук AC-045…AC-048: грейпы `статическ|static` + `gramax-cli`.
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
  fail_msg "ac-047: SKILL.md навыка export отсутствует ($SKILL_MD) — рецепт статического портала не создан (красная причина AC-047)"
  exit 1
fi

# AC-047, литеральные грейпы требования: генерация статического сайта через gramax-cli
# (деплой портала — за границей навыка, указатель на docs; FR-139).
assert_grep_regex_i "$SKILL_MD" 'статическ|static' \
  "AC-047 — SKILL.md обязан проговаривать статический портал (FR-139)"
assert_grep "$SKILL_MD" 'gramax-cli' \
  "AC-047 — SKILL.md обязан давать рецепт генерации через gramax-cli (FR-139)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-047: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-047: рецепт статического портала (gramax-cli) присутствует в SKILL.md"
