#!/usr/bin/env bash
# tests/gramax/export-skill/ac-042-pdf-template-facts.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-042 (FR-133).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»,
#   хук AC-042: грейпы `.page`, `title-page`, колонтитул/header/footer.
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
  fail_msg "ac-042: SKILL.md навыка export отсутствует ($SKILL_MD) — guidance PDF-шаблона не создан (красная причина AC-042)"
  exit 1
fi

# AC-042, литеральные грейпы требования: документированные классы CSS-шаблона PDF
# и колонтитулы (BR-007: только факты, раскрытые в RES-007).
assert_grep_regex "$SKILL_MD" '\.page' \
  "AC-042 — SKILL.md обязан называть класс CSS-шаблона PDF .page (FR-133)"
assert_grep_regex "$SKILL_MD" 'title-page' \
  "AC-042 — SKILL.md обязан называть класс .title-page (FR-133)"
assert_grep_regex_i "$SKILL_MD" 'колонтитул|header|footer' \
  "AC-042 — SKILL.md обязан проговаривать колонтитулы (headers/footers) шаблона PDF (FR-133)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-042: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-042: факты PDF-шаблона (.page, .title-page, колонтитулы) присутствуют в SKILL.md"
