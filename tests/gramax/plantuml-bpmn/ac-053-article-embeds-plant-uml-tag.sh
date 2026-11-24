#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-053-article-embeds-plant-uml-tag.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-053 (FR-144, FR-141).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт
#   тегов (Q-4)»: канонический вывод — минимальный самозакрывающийся
#   `<plant-uml path="…"/>` с пустой строкой до и после; атрибуты сверх path —
#   только по явному запросу; «Дефолты размеров не изобретаются» (edge case
#   дизайна: «дефолтных width/height нет — отличие от mermaid-AC-004/005,
#   не копировать их сюда»).
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует. Контракт —
#   спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).
# Литеральна AC-053 (`grep -q '<plant-uml path="./' <page>.md`) — на статью
# после живой сессии авторства (qa-runner); статическая половина: секция
# «Теги вставки» обязана документировать каноническую форму. Отрицательная
# проверка «навык не копирует mermaid-дефолт 800px/450px» здесь дана
# позитивной формой «по явному запросу» (пин-язык дизайна Q-4) — негативный
# grep по «800px» ловил бы и честную оговорку «в отличие от mermaid — без
# дефолтов» (false positive на анти-примере).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"

# Гейт существования — до контентных грейпов: ровно одна красная причина.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-053: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — контракт вставки тега не реализован (красная причина AC-053)"
  exit 1
fi

# --- AC-053/FR-144: каноническая форма тега ---
assert_grep "$SKILL_MD" '<plant-uml path="./' \
  "AC-053 — SKILL.md обязан документировать тег <plant-uml path=\"./…\"/> (литераль AC-053)"
assert_grep "$SKILL_MD" '/>' \
  "AC-053/FR-144 — SKILL.md обязан фиксировать самозакрывающуюся форму тега (дизайн: «минимальная самозакрывающаяся форма»)"
assert_grep_regex_i "$SKILL_MD" 'пуст' \
  "AC-053/FR-144 — SKILL.md обязан требовать пустую строку до и после тега (FR-144, прецедент mermaid/ADR-0010)"
assert_grep_regex_i "$SKILL_MD" 'явному запрос' \
  "AC-053 (Q-4, edge case дизайна) — атрибуты сверх path (title/width/height/float/scale) только по явному запросу (пин-язык таблицы Q-4)"
assert_no_grep "$SKILL_MD" "Атрибуты \`width\` и \`height\` обязательны" \
  "AC-053 (Q-4, edge case дизайна) — mermaid-форма «атрибуты width и height обязательны» не переносится в plantuml (дефолтных размеров нет)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-053: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-053: каноническая форма <plant-uml path=\"./…\"/> документирована (самозакрывающийся тег, пустые строки, атрибуты только по явному запросу)"
