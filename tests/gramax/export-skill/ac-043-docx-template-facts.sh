#!/usr/bin/env bash
# tests/gramax/export-skill/ac-043-docx-template-facts.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-043 (FR-134).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»,
#   хук AC-042…AC-044: грейпы `dotx`, `word` (строка AC-043).
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
  fail_msg "ac-043: SKILL.md навыка export отсутствует ($SKILL_MD) — guidance DOCX-шаблона не создан (красная причина AC-043)"
  exit 1
fi

# AC-043, литеральные грейпы требования: формат шаблона DOCX и авторство в Word
# (BR-007: агент не авторит бинарный .dotx — навык только инструктирует).
assert_grep "$SKILL_MD" 'dotx' \
  "AC-043 — SKILL.md обязан называть формат шаблона DOCX (.docx/.dotx) (FR-134)"
assert_grep_regex_i "$SKILL_MD" 'word' \
  "AC-043 — SKILL.md обязан называть авторство шаблона в Word (FR-134)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-043: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-043: факты DOCX-шаблона (.dotx, авторство в Word) присутствуют в SKILL.md"
