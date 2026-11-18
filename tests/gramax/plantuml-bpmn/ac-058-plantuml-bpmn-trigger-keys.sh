#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-058-plantuml-bpmn-trigger-keys.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-058 (FR-146).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт
#   триггеров (description и fallback)»: целевой description plantuml несёт
#   позитивные ключи FR-146 (plantuml, plant-uml, puml, UML-диаграмма, Salt,
#   макет интерфейса, bpmn, BPMN-процесс, Camunda) и негативную демаркацию
#   («Не для: mermaid DSL → gramax:mermaid; drawio / .drawio → gramax:drawio»);
#   файл-план: drawio/SKILL.md получает анти-триггер «НЕ для PlantUML/BPMN»,
#   из его fallback-строки «Подходит для сложных схем, BPMN, кастомных стилей»
#   BPMN убирается с указателем на gramax:plantuml. Generic-триггеры («нарисуй
#   диаграмму») навык не ловит — владелец gramax:mermaid (ADR-0009 Решение 1).
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует. Замер
#   литералы AC-058 на 9355b69: голый grep дерева уже зелёный — «BPMN» упоминают
#   drawio/fallback-строки mermaid (drawio/SKILL.md:65, mermaid/SKILL.md:27),
#   т.е. литераль AC-058 без привязки к description зелёная по ЛОЖНОЙ причине
#   (BPMN числится «подходит» у drawio). Поэтому stub привязывает проверку
#   ключей к description конкретного владельца (plantuml) и к переносу BPMN из
#   «подходит»-списка drawio. Контракт — спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"
DRAWIO_MD="$ROOT/plugins/gramax/skills/drawio/SKILL.md"

# Гейт существования — до контентных грейпов: ровно одна красная причина.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-058: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — plantuml/bpmn-триггерные ключи некому нести (красная причина AC-058)"
  exit 1
fi

# --- AC-058/FR-146: девять явных ключей — ровно список FR-146 — в description ---
DESC="$(sed -n 's/^description:[[:space:]]*//p' "$SKILL_MD")"
if [ -z "$DESC" ]; then
  echo "  FAIL: AC-058 — во frontmatter обязана быть однострочная description (контракт триггеров, дизайн §«Контракт триггеров»)" >&2
  FAIL=$((FAIL + 1))
else
  for trigger in 'plantuml' 'plant-uml' 'puml' 'UML-диаграмма' 'Salt' 'макет интерфейса' 'bpmn' 'BPMN-процесс' 'Camunda'; do
    if ! printf '%s' "$DESC" | grep -qiE "$trigger"; then
      echo "  FAIL: AC-058/FR-146 — description обязан называть триггер «$trigger»" >&2
      FAIL=$((FAIL + 1))
    fi
  done
  # Негативная демаркация (пин-текст дизайна): открытие + указатели на соседей.
  if ! printf '%s' "$DESC" | grep -qiE 'Только для PlantUML'; then
    echo "  FAIL: AC-058 (пин-текст дизайна) — description обязан открываться «Только для PlantUML- и BPMN-диаграмм — НЕ для mermaid и drawio»" >&2
    FAIL=$((FAIL + 1))
  fi
  for neighbour in 'gramax:mermaid' 'gramax:drawio'; do
    if ! printf '%s' "$DESC" | grep -qiF "$neighbour"; then
      echo "  FAIL: AC-058 (пин-текст дизайна) — description обязан содержать анти-триггер с указателем на $neighbour" >&2
      FAIL=$((FAIL + 1))
    fi
  done
fi

# --- FR-146 (файл-план дизайна): drawio теряет BPMN из «подходит»-списка ---
if [ ! -f "$DRAWIO_MD" ]; then
  echo "  FAIL: AC-058 (файл-план дизайна) — drawio/SKILL.md не найден ($DRAWIO_MD)" >&2
  FAIL=$((FAIL + 1))
else
  assert_no_grep_regex "$DRAWIO_MD" 'сложных схем, BPMN' \
    "AC-058 (файл-план дизайна) — из fallback-строки drawio («Подходит для сложных схем, BPMN, кастомных стилей») BPMN обязан быть убран"
  DDESC="$(sed -n 's/^description:[[:space:]]*//p' "$DRAWIO_MD")"
  if ! printf '%s' "$DDESC" | grep -qiE 'PlantUML/BPMN|gramax:plantuml'; then
    echo "  FAIL: AC-058 (файл-план дизайна) — description drawio обязан нести анти-триггер «НЕ для PlantUML/BPMN → gramax:plantuml»" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-058: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-058: девять ключей FR-146 в description plantuml, демаркация на месте, BPMN выведен из «подходит»-списка drawio"
