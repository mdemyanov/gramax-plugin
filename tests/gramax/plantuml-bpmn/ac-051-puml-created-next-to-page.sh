#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-051-puml-created-next-to-page.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-051 (FR-141, FR-147, NFR-063).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт с
#   QA-author» (AC-051…AC-056, AC-058 — smoke/static на фикстурном каталоге и
#   дереве навыков), «Инстанцирование конвенции именования (FR-147)», «План
#   компонентов и файлов» (строка plantuml/SKILL.md).
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует (замер: в
#   plugins/gramax/skills/ — comments-read, comments-write, drawio, mermaid,
#   writer). Контракт — спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011; unit неприменим — исполняемого кода в навыке
#   нет, конвертационные скрипты запрещены BR-008).
# Литеральна AC-051 (`test -f <dir>/<page-slug>-<diagram-slug>.puml`) — на
# артефакт живой сессии авторства; до реализации единственный честный красный —
# отсутствие навыка. Статическая половина: SKILL.md обязан документировать
# workflow «.puml в той же директории, что target_page» и конвенцию именования
# (дословная инстанциация mermaid/ADR-0010: _index.md → имя родительской
# директории; kebab-case, ASCII, ≤ 30; кириллица → перевод/ввод, без
# автотранслитерации — NFR-063).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"
FIXTURES="$SCRIPT_DIR/fixtures/doc-root"

# Гейт существования — до контентных грейпов: пока предмета нет, падение
# обязано называть ровно одну причину (навык не создан), а не россыпь
# «паттерн не найден».
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-051: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — авторство PlantUML не реализовано (красная причина AC-051)"
  exit 1
fi

# --- AC-051/FR-141: .puml пишется рядом со статьёй ---
assert_grep_regex_i "$SKILL_MD" 'target_page' \
  "AC-051/FR-141 — SKILL.md обязан оперировать target_page (прецедент mermaid workflow)"
assert_grep_regex_i "$SKILL_MD" '\.puml' \
  "AC-051/FR-141 — SKILL.md обязан называть .puml-файл как артефакт авторства"
assert_grep_regex_i "$SKILL_MD" 'той же директор|рядом со стать' \
  "AC-051/FR-141 — SKILL.md обязан требовать писать .puml в той же директории, что target_page (FR-141; дизайн: «файл — в той же директории, что target_page, не в assets-папке»)"

# --- AC-051/FR-147: конвенция именования — дословная инстанциация mermaid ---
assert_grep_regex_i "$SKILL_MD" 'Naming convention|именован' \
  "AC-051/FR-147 — SKILL.md обязан нести секцию Naming convention (скелет дизайна)"
assert_grep "$SKILL_MD" '<page-slug>-<diagram-slug>.puml' \
  "AC-051/FR-147 — SKILL.md обязан фиксировать шаблон <page-slug>-<diagram-slug>.puml"
assert_grep_regex "$SKILL_MD" '_index\.md' \
  "AC-051/FR-147 — SKILL.md обязан нести спецкейс _index.md → имя родительской директории (инстанциация FR-147)"
assert_grep_regex_i "$SKILL_MD" 'kebab-case' \
  "AC-051/FR-147 — SKILL.md обязан требовать kebab-case для <diagram-slug>"
assert_grep_regex "$SKILL_MD" '30' \
  "AC-051/FR-147 — SKILL.md обязан нести предел ≤ 30 символов для <diagram-slug>"
assert_grep_regex_i "$SKILL_MD" 'кириллиц' \
  "AC-051/FR-147/NFR-063 — SKILL.md обязан нести правило кириллицы (семантический перевод / ввод пользователем)"
assert_no_grep_regex_i "$SKILL_MD" 'автотранслитер' \
  "AC-051/FR-147/NFR-063 — автотранслитерация запрещена (дизайн: «без автотранслитерации, прецедент ADR-0010 Решение 2»)"

# --- Фикстурная половина (дизайн, «Контракт с QA-author») ---
assert_file_exists "$FIXTURES/overview.md" \
  "AC-051 (фикстура) — стандартная статья-фикстура обязана существовать"
assert_file_exists "$FIXTURES/process/_index.md" \
  "AC-051 (фикстура, edge case дизайна) — статья с _index.md-кейсом обязана существовать"
assert_file_exists "$FIXTURES/overview-component-diagram.puml" \
  "AC-051 (фикстура) — существующий .puml для коллизии обязан существовать"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-051: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-051: workflow .puml-рядом-со-статьёй и конвенция именования документированы, фикстуры на месте"
