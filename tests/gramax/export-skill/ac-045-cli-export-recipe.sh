#!/usr/bin/env bash
# tests/gramax/export-skill/ac-045-cli-export-recipe.sh
# Требование: docs/30-requirements/2026-11-18-export-skill-requirement.md, AC-045 (FR-136).
# Дизайн: docs/40-architecture/2026-11-18-export-skill-design.md — «Контракт с QA-author»,
#   edge case 1: экранирование литерала «-f docx|pdf» в regex — пайп в альтернации;
#   тест обязан матчить и запасную ветку `-f pdf`.
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
  fail_msg "ac-045: SKILL.md навыка export отсутствует ($SKILL_MD) — CLI-рецепт экспорта не создан (красная причина AC-045)"
  exit 1
fi

# AC-045, первая часть литералы требования: вызов CLI-экспорта.
assert_grep "$SKILL_MD" 'gramax-cli export' \
  "AC-045 — SKILL.md обязан давать рецепт gramax-cli export (FR-136)"

# AC-045, вторая часть литералы: grep -Eq -- '-f docx\|pdf|-f pdf'.
# Инлайн, не через assert_grep_regex: паттерн начинается с «-» — обёртка lib без «--»
# скормила бы его grep как опцию; «--» взят из литералы AC. В ERE «\|» — литеральный
# пайп: альтернация матчит «-f docx|pdf» и запасную форму «-f pdf» (edge case 1 дизайна).
if ! grep -Eq -- '-f docx\|pdf|-f pdf' "$SKILL_MD"; then
  echo "  FAIL: AC-045 — SKILL.md обязан матчить форму флага «-f docx|pdf» либо запасную «-f pdf» (FR-136)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-045: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-045: CLI-рецепт (gramax-cli export -f docx|pdf) присутствует в SKILL.md"
