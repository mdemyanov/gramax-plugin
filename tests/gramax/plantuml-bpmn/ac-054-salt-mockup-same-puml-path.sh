#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-054-salt-mockup-same-puml-path.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-054 (FR-142).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Окружение
#   рендера и Salt (Q-5)»: Salt остаётся в scope авторства тем же контуром —
#   @startsalt/@endsalt в тот же .puml, вставка штатным тегом <plant-uml path>,
#   отдельного механизма нет; секция «Окружение рендера» обязана нести оговорку
#   о серверном рендере (DIAGRAM_RENDERER_SERVICE_URL). Edge case дизайна:
#   «Salt-макет начинается с @startsalt (AC-054)».
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует. Контракт —
#   спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).
# Литеральна AC-054 (`grep -q '@startsalt' <file>.puml`) — на артефакт авторства
# (Salt-макет из живой сессии, qa-runner); фикстуры-образца Salt дизайн не
# требует (состав фикстур закрыт списком «Контракта с QA-author») — stub
# проверяет контрактную половину на SKILL.md.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"

# Гейт существования — до контентных грейпов: ровно одна красная причина.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-054: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — Salt-контур не реализован (красная причина AC-054)"
  exit 1
fi

# --- AC-054/FR-142: Salt — тот же контур, отдельного механизма нет ---
assert_grep "$SKILL_MD" '@startsalt' \
  "AC-054/FR-142 — SKILL.md обязан называть @startsalt (Salt-каркас, литераль AC-054)"
assert_grep "$SKILL_MD" '@endsalt' \
  "AC-054/FR-142 — SKILL.md обязан называть @endsalt (закрытие Salt-каркаса)"
assert_grep_regex_i "$SKILL_MD" 'salt' \
  "AC-054/FR-142 — SKILL.md обязан покрывать Salt-макеты интерфейсов (триггер FR-146)"
assert_grep_regex_i "$SKILL_MD" 'тот же|штатн|отдельного механизма' \
  "AC-054/FR-142 — SKILL.md обязан фиксировать «Salt в тот же .puml, штатный тег <plant-uml path>, отдельного механизма нет» (дизайн Q-5)"

# --- Q-5: оговорка окружения рендера (обязательная секция скелета) ---
assert_grep_regex_i "$SKILL_MD" 'Окружение рендера' \
  "AC-054/Q-5 — SKILL.md обязан нести секцию «Окружение рендера» (скелет дизайна: рендер PlantUML/Salt серверный, требует DIAGRAM_RENDERER_SERVICE_URL)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-054: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-054: Salt-контур документирован (@startsalt в тот же .puml, штатный тег) + оговорка окружения рендера"
