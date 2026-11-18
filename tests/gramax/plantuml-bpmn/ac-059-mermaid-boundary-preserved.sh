#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-059-mermaid-boundary-preserved.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-059 (FR-146, BR-011); формулировка действует при выборе Q-1(a)/(c) —
#   ADR-0023 выбрал (a), stub реализует её как есть (прецедент условных AC:
#   AC-006, 2026-08-13-link-form-contract.md).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт
#   триггеров»: fallback-диалог mermaid расширяется до четырёх опций
#   (mermaid/plantuml/bpmn/drawio), дефолт mermaid без изменений (BR-011);
#   литералы `@startuml` и `.bpmn` ЗАПРЕЩЕНЫ в mermaid/SKILL.md целиком (слово
#   «bpmn» и тег `<bpmn path>` — допустимы); description получает анти-триггер
#   «Не для PlantUML/BPMN → gramax:plantuml»; узкий контракт «Только для
#   диаграмм в синтаксисе Mermaid DSL» сохраняется.
# Природа: гибрид warden + failing stub (обе половины честные):
#   (а) warden-половина (литераль AC-059) — зелёная по рождению: замер на
#       9355b69 даёт `grep -icE '@startuml|\.bpmn'` = 0. Запрет литералов
#       стережёт файл всегда; принудительно красить запрещено (green-born =
#       warden, never forced red);
#   (б) контрактная половина — красная на 9355b69: fallback-диалог mermaid всё
#       ещё двухопционный, «BPMN» числится «подходит» у drawio-опции
#       (mermaid/SKILL.md:27), анти-триггера в description нет. Контракт —
#       спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
MERMAID_MD="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

if [ ! -f "$MERMAID_MD" ]; then
  fail_msg "ac-059: mermaid/SKILL.md не найден ($MERMAID_MD) — предмет границы триггеров отсутствует"
  exit 1
fi

# (а) Warden — литераль AC-059, исполняется ВСЕГДА: литералы @startuml и .bpmn
# запрещены в mermaid/SKILL.md целиком (дизайн: слово «bpmn» и тег <bpmn path>
# — допустимы).
LITERAL_COUNT="$(grep -icE '@startuml|\.bpmn' "$MERMAID_MD")"
assert_eq "$LITERAL_COUNT" "0" \
  "AC-059 (литераль, warden) — в mermaid/SKILL.md запрещены литералы @startuml и .bpmn: mermaid не взял на себя plantuml/bpmn-авторство"

# (б) Контрактная половина — расширение fallback-диалога (пин-текст дизайна).
# Опции plantuml и bpmn появляются в диалоге с указателем владельца.
assert_grep_regex_i "$MERMAID_MD" '\*\*plantuml\*\*' \
  "AC-059/FR-146 — fallback-диалог mermaid обязан нести опцию **plantuml** (пин-текст дизайна: 4 опции)"
assert_grep_regex_i "$MERMAID_MD" '\*\*bpmn\*\*' \
  "AC-059/FR-146 — fallback-диалог mermaid обязан нести опцию **bpmn** (пин-текст дизайна: 4 опции)"
PLANTUML_POINTERS="$(grep -c 'gramax:plantuml' "$MERMAID_MD" 2>/dev/null || true)"
if [ "${PLANTUML_POINTERS:-0}" -lt 2 ]; then
  echo "  FAIL: AC-059/FR-146 — mermaid/SKILL.md обязан звать gramax:plantuml минимум дважды (анти-триггер в description + указатели опций 2/3 fallback-диалога)" >&2
  FAIL=$((FAIL + 1))
fi
# Из drawio-опции диалога «Подходит для сложных схем, BPMN, кастомных стилей»
# BPMN убирается — теперь это своя опция с владельцем gramax:plantuml.
assert_no_grep_regex "$MERMAID_MD" 'сложных схем, BPMN' \
  "AC-059/FR-146 (файл-план дизайна) — из fallback-строки drawio в mermaid/SKILL.md «BPMN» обязан быть убран"
# Description получает анти-триггер (пин-текст дизайна).
MDESC="$(sed -n 's/^description:[[:space:]]*//p' "$MERMAID_MD")"
if ! printf '%s' "$MDESC" | grep -qiE 'PlantUML/BPMN'; then
  echo "  FAIL: AC-059/FR-146 — description mermaid обязан нести анти-триггер «Не для PlantUML/BPMN → gramax:plantuml»" >&2
  FAIL=$((FAIL + 1))
fi

# --- BR-011: mermaid-контракт не меняется по существу ---
assert_grep "$MERMAID_MD" 'Только для диаграмм в синтаксисе Mermaid DSL' \
  "AC-059/BR-011 — узкий контракт «Только для диаграмм в синтаксисе Mermaid DSL» обязан сохраниться (FR-146)"
assert_grep_regex "$MERMAID_MD" 'По умолчанию — \*\*mermaid\*\*' \
  "AC-059/BR-011 (ADR-0023 Решение 1) — дефолт неявного запроса остаётся mermaid («По умолчанию — mermaid, если не укажешь»)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-059: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-059: граница триггеров mermaid/plantuml на месте (fallback 4 опции, анти-триггер, литералы @startuml/.bpmn отсутствуют, дефолт и узкий контракт сохранены)"
