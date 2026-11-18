#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-057-no-conversion-scripts-invariant.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-057 (NFR-060, BR-008 — анти-ADR-0008).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Стоп-правило
#   BR-008 — нет конвертационных пайплайнов»: точка носителя 1 — секция
#   «Стоп-правило» в plantuml/SKILL.md (обязательная); BR-009 синхронно —
#   единственные артефакты навыка: исходник + тег-ссылка. «Контракт с QA-author»:
#   AC-057 — smoke/static, `grep -ic` по plugins/gramax/scripts/, «анти-ADR-0008
#   инвариант; нулевой счётчик».
# Природа: гибрид warden + failing stub (оба статуса честные):
#   (а) warden-половина (литераль AC-057) — зелёная по рождению: замер на
#       9355b69 даёт счётчик 0 (в plugins/gramax/scripts/ нет plantuml/bpmn-
#       скриптов). Инвариант «конверсия не появляется» не красится принудительно
#       — он стережёт дерево всегда, включая сейчас (green-born = warden, never
#       forced red);
#   (б) контрактная половина — красная на 9355b69: plugins/gramax/skills/
#       plantuml/ отсутствует, обязательная секция «Стоп-правило» (точка
#       носителя BR-008) не написана. Контракт — спецификация, не описание
#       текущего кода.
# Уровень: integration (ADR-0011).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"
SCRIPTS_DIR="$ROOT/plugins/gramax/scripts"

# (а) Warden — литераль AC-057, исполняется ВСЕГДА (инвариант живёт и до, и
# после реализации): ни одного plantuml/bpmn-скрипта в plugins/gramax/scripts/.
if [ ! -d "$SCRIPTS_DIR" ]; then
  fail_msg "ac-057: каталог $SCRIPTS_DIR отсутствует — проверять нулевой счётчик не на чем (ADR-007 Д1: «не смог проверить» ≠ «нечего проверять»)"
  exit 1
fi
SCRIPT_COUNT="$(ls "$SCRIPTS_DIR" | grep -icE 'plantuml|plant-uml|bpmn')"
assert_eq "$SCRIPT_COUNT" "0" \
  "AC-057/NFR-060 (анти-ADR-0008) — в plugins/gramax/scripts/ не должно появиться ни одного plantuml/bpmn-скрипта (BR-008: конвертационный pipeline не строится ни под каким предлогом)"

# Гейт существования предмета — красная причина stub'а (контрактная половина).
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-057: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — обязательная секция «Стоп-правило» (точка носителя BR-008) не написана (красная причина AC-057)"
  exit 1
fi

# (б) Контрактная половина: секция «Стоп-правило» (скелет дизайна).
assert_grep_regex_i "$SKILL_MD" 'Стоп-правило' \
  "AC-057/BR-008 — SKILL.md обязан нести секцию «Стоп-правило» (обязательная точка носителя, дизайн BR-008 п.1)"
assert_grep_regex_i "$SKILL_MD" 'SVG|PNG' \
  "AC-057/BR-009 — SKILL.md обязан запрещать конвертацию .puml/.bpmn в SVG/PNG и локальные рендеры (PlantUML/Java, npm, draw.io desktop)"
assert_grep_regex_i "$SKILL_MD" 'эскалаци' \
  "AC-057/BR-008 — SKILL.md обязан предписывать эскалацию пользователю к SA/PM, а не строительство pipeline (стоп-условие требования)"
assert_no_grep_regex_i "$SKILL_MD" 'конвертируй|вызови (plantuml|java|npm)' \
  "AC-057/BR-008 — SKILL.md не должен предписывать конвертацию или вызов локальных рендер-бинарников"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-057: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-057: нулевой счётчик plantuml/bpmn-скриптов (warden живой) + секция «Стоп-правило» на месте"
