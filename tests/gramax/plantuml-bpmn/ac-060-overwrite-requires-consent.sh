#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-060-overwrite-requires-consent.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-060 (FR-148, NFR-061) — smoke-тест, не одна строка: повторный вызов с тем
#   же именем файла и ответом «нет» на перезапись оставляет .puml/.bpmn
#   неизменным (сравнение содержимого до/после, diff пуст).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Контракт с
#   QA-author»: AC-060 — smoke поведенческий («два прогона над фикстурой, diff
#   до/после; фиксация ответа «нет» на перезапись», прецедент mermaid
#   AC-008/AC-009 ADR-0010); «Инстанцирование конвенции именования»: алгоритм
#   коллизии — прочитать первые 5 строк, показать, предложить перезаписать /
#   другое имя / отмена; без явного «перезаписать» файл не трогается.
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует. Контракт —
#   спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).
# Граница автоматизации (для qa-runner, зафиксирована в at-design.md): сама
# пара прогонов «вызов навыка → отказ → повторный вызов → diff» требует живой
# сессии агента — исполняемой точки входа у навыка нет, и скрипт-эмулятор
# запрещён BR-008. Suite несёт контрактную половину (алгоритм коллизии
# обязан быть в SKILL.md) и фикстуру дизайна (существующий .puml для коллизии);
# поведенческий smoke двух прогонов — шаг qa-runner при приёмке.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"
FIXTURE_PUML="$SCRIPT_DIR/fixtures/doc-root/overview-component-diagram.puml"

# Фикстура коллизии (состав фикстур по дизайну) — должна существовать уже сейчас.
assert_file_exists "$FIXTURE_PUML" \
  "AC-060 (фикстура дизайна) — существующий .puml для коллизии обязан существовать"

# Гейт существования предмета — красная причина stub'а.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-060: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — алгоритм коллизии/защита от перезаписи не реализованы (красная причина AC-060)"
  exit 1
fi

# --- AC-060/FR-148: алгоритм коллизии (инстанциация mermaid/ADR-0010) ---
assert_grep_regex "$SKILL_MD" '5 строк' \
  "AC-060/FR-148 — SKILL.md обязан предписывать читать первые 5 строк существующего файла (дизайн: «прочитать первые 5 строк»)"
assert_grep_regex_i "$SKILL_MD" 'перезаписать' \
  "AC-060/FR-148 — SKILL.md обязан предлагать опцию «перезаписать»"
assert_grep_regex_i "$SKILL_MD" 'другое имя' \
  "AC-060/FR-148 — SKILL.md обязан предлагать опцию «другое имя»"
assert_grep_regex_i "$SKILL_MD" 'отмен' \
  "AC-060/FR-148 — SKILL.md обязан предлагать опцию «отмена»"
assert_grep_regex_i "$SKILL_MD" 'Без явного' \
  "AC-060/FR-148/NFR-061 — SKILL.md обязан фиксировать «без явного «перезаписать» файл не трогается» (BR-010)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-060: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-060: алгоритм коллизии документирован (5 строк → показать → перезаписать/другое имя/отмена, без явного согласия файл не трогается); фикстура коллизии на месте"
