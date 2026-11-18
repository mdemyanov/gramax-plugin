#!/usr/bin/env bash
# tests/gramax/export-skill/ac-046-ci-stage-recipe.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-046 (FR-137).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»,
#   хук AC-045…AC-048: грейпы `gitlab-ci`, `EXPORT_FILE_PATH`.
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
  fail_msg "ac-046: SKILL.md навыка export отсутствует ($SKILL_MD) — рецепт CI-стадии не создан (красная причина AC-046)"
  exit 1
fi

# AC-046, литеральные грейпы требования: стадия .gitlab-ci.yml с копируемым блоком
# и переменной пути результирующего файла (BR-007: только факты из RES-007).
assert_grep "$SKILL_MD" 'gitlab-ci' \
  "AC-046 — SKILL.md обязан давать стадию .gitlab-ci.yml (FR-137)"
assert_grep "$SKILL_MD" 'EXPORT_FILE_PATH' \
  "AC-046 — SKILL.md обязан называть переменную EXPORT_FILE_PATH (FR-137)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-046: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-046: рецепт CI-стадии (.gitlab-ci.yml, EXPORT_FILE_PATH) присутствует в SKILL.md"
