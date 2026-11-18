#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-052-puml-pure-plantuml-content.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-052 (FR-141).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт с
#   QA-author», edge case «.puml-чистота: первая строка @start…, внутри нет
#   <plant-uml и ```plant-uml»; секция «PlantUML» скелета SKILL.md.
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует — некем
#   произвести чистый .puml. Контракт — спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).
# Литеральна AC-052 (`head -1 | grep '^@start'` + отсутствие теговой разметки
# внутри) — на артефакт авторства; здесь проверяется двумя половинами:
# (1) SKILL.md обязан документировать «чистый PlantUML без Gramax-разметки»;
# (2) механика литеральной однострочности доказывается на фикстуре дизайна
#     (существующий .puml для коллизии — чистый исходник: первая строка
#     @startuml, внутри нет теговой разметки). Так ловится masked failure
#     «проверка зелёная по пустоте»: сама однострочность исполнена и зелёная,
#     красит ровно отсутствие навыка.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"
FIXTURE_PUML="$SCRIPT_DIR/fixtures/doc-root/overview-component-diagram.puml"

# (2) Механика литералы AC-052 — ДО гейта существования: однострочность обязана
# исполняться и быть осмысленной независимо от фазы реализации.
if [ ! -f "$FIXTURE_PUML" ]; then
  fail_msg "ac-052: фикстура $FIXTURE_PUML отсутствует — механика проверки не исполнить (ADR-007 Д1: «не смог проверить» ≠ «нечего проверять»)"
  exit 1
fi
if ! head -1 "$FIXTURE_PUML" | grep -q '^@start'; then
  echo "  FAIL: AC-052 (механика на фикстуре) — первая строка .puml обязана начинаться с @start (литераль AC-052)" >&2
  FAIL=$((FAIL + 1))
fi
if grep -qE '<plant-uml|```plant-uml' "$FIXTURE_PUML"; then
  echo "  FAIL: AC-052 (механика на фикстуре) — внутри .puml не должно быть теговой разметки <plant-uml / \`\`\`plant-uml (литераль AC-052)" >&2
  FAIL=$((FAIL + 1))
fi

# Гейт существования предмета — красная причина stub'а.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-052: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — контракт чистоты .puml не реализован (красная причина AC-052)"
  exit 1
fi

# (1) Контрактная половина: SKILL.md документирует чистый PlantUML (FR-141).
assert_grep "$SKILL_MD" '@startuml' \
  "AC-052/FR-141 — SKILL.md обязан называть @startuml (каркас PlantUML)"
assert_grep "$SKILL_MD" '@enduml' \
  "AC-052/FR-141 — SKILL.md обязан называть @enduml (закрытие каркаса)"
assert_grep_regex_i "$SKILL_MD" 'чист' \
  "AC-052/FR-141 — SKILL.md обязан требовать чистый PlantUML без Gramax-разметки и обёрток (прецедент mermaid: «только чистый DSL»)"
assert_grep_regex_i "$SKILL_MD" 'без.*(разметк|обёртк)' \
  "AC-052/FR-141 — SKILL.md обязан запрещать Gramax-разметку/обёртки внутри .puml (дизайн: «без Gramax-разметки и без обёрток»)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-052: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-052: контракт чистоты .puml документирован; литеральная однострочность исполнена на фикстуре (первая строка @start, разметки внутри нет)"
