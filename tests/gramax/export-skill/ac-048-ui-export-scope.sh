#!/usr/bin/env bash
# tests/gramax/export-skill/ac-048-ui-export-scope.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-048 (FR-138).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»,
#   хук AC-045…AC-048: грейпы `приложени`, `раздел`, `каталог`.
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
  fail_msg "ac-048: SKILL.md навыка export отсутствует ($SKILL_MD) — guidance UI-экспорта не создан (красная причина AC-048)"
  exit 1
fi

# AC-048, литеральные грейпы требования: путь пользователя в UI приложения и портала,
# скоуп статья/раздел/каталог (FR-138: текст описывает путь, не имитирует действия).
assert_grep_regex_i "$SKILL_MD" 'приложени' \
  "AC-048 — SKILL.md обязан проговаривать экспорт из приложения (FR-138)"
assert_grep_regex_i "$SKILL_MD" 'раздел' \
  "AC-048 — SKILL.md обязан проговаривать скоуп «раздел» (FR-138)"
assert_grep_regex_i "$SKILL_MD" 'каталог' \
  "AC-048 — SKILL.md обязан проговаривать скоуп «каталог» (FR-138)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-048: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-048: guidance UI-экспорта (приложение, раздел, каталог) присутствует в SKILL.md"
