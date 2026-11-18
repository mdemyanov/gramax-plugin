#!/usr/bin/env bash
# tests/gramax/plantuml-bpmn/ac-061-inline-not-silently-migrated.sh
# Требование: docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md,
#   AC-061 (FR-145, BR-010) — smoke-тест, не одна строка: на фикстуре с
#   ```plant-uml-блоком прогон навыка без пользовательского подтверждения
#   оставляет статью неизменной (diff пуст).
# Дизайн: docs/40-architecture/2026-11-18-plantuml-bpmn-design.md — «Политика
#   inline-формы (Q-2)», решение (i): file-based канон; inline распознаётся при
#   чтении target_page, уведомление + предложение точечной миграции (извлечь
#   исходник в `<page-slug>-existing.puml`, заменить блок на тег; опции блока
#   переносятся в атрибуты тега 1:1 — title/scale/float по схеме движка);
#   БЕЗ явного подтверждения файл не трогается; batch-миграция вне scope.
# Природа: failing stub — контракт специфицирован, реализация (Dev) ещё не создана.
#   Красный на 9355b69: plugins/gramax/skills/plantuml/ отсутствует. Контракт —
#   спецификация, не описание текущего кода.
# Уровень: integration (ADR-0011).
# Граница автоматизации (для qa-runner, зафиксирована в at-design.md): сам
# «прогон навыка без подтверждения» — живая сессия агента; suite несёт
# контрактную половину (секция Backward compatibility с распознаванием inline,
# 1:1-перенос опций, запрет молчаливой правки) и фикстуру дизайна
# (статья с inline ```plant-uml и опциями {title, scale, float});
# поведенческий smoke — шаг qa-runner при приёмке (прецедент mermaid
# AC-008/AC-009 ADR-0010).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/plantuml/SKILL.md"
FIXTURE_INLINE="$SCRIPT_DIR/fixtures/doc-root/legacy-inline.md"

# Самопроверка фикстуры (состав фикстур по дизайну): inline-блок с опциями.
assert_file_exists "$FIXTURE_INLINE" \
  "AC-061 (фикстура дизайна) — статья с inline-блоком \`\`\`plant-uml обязана существовать"
assert_grep_regex "$FIXTURE_INLINE" '```plant-uml' \
  "AC-061 (фикстура) — в фикстуре обязан быть fenced-блок \`\`\`plant-uml"
for option in 'title' 'scale' 'float'; do
  assert_grep "$FIXTURE_INLINE" "$option" \
    "AC-061 (фикстура) — inline-блок фикстуры обязан нести опцию $option (FR-145: {title, scale, float})"
done

# Гейт существования предмета — красная причина stub'а.
if [ ! -f "$SKILL_MD" ]; then
  fail_msg "ac-061: SKILL.md навыка plantuml отсутствует ($SKILL_MD) — inline-политика (распознавание, миграция по подтверждению) не реализована (красная причина AC-061)"
  exit 1
fi

# --- AC-061/FR-145: секция Backward compatibility (скелет дизайна) ---
assert_grep_regex_i "$SKILL_MD" 'Backward compatib|inline' \
  "AC-061/FR-145 — SKILL.md обязан нести секцию Backward compatibility (inline-форма; скелет дизайна)"
assert_grep_regex "$SKILL_MD" '```plant-uml|inline-блок' \
  "AC-061/FR-145 — SKILL.md обязан документировать распознавание inline-блока \`\`\`plant-uml при чтении target_page"
assert_grep_regex_i "$SKILL_MD" 'existing' \
  "AC-061/FR-145 (Q-2) — SKILL.md обязан предлагать миграцию в <page-slug>-existing.puml (пин-язык дизайна)"
# Опции блока переносятся в атрибуты тега 1:1 (соответствие схеме движка, Q-4).
for option in 'title' 'scale' 'float'; do
  assert_grep "$SKILL_MD" "$option" \
    "AC-061/FR-145 (Q-2) — SKILL.md обязан документировать перенос опции $option в атрибут тега 1:1"
done
# BR-010: без явного подтверждения файл не трогается.
assert_grep_regex_i "$SKILL_MD" 'подтвержд' \
  "AC-061/FR-145/BR-010 — SKILL.md обязан фиксировать «без явного подтверждения файл не трогается» (молчаливая перезапись/миграция запрещены)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-061: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-061: inline-политика документирована (распознавание, existing-миграция, опции 1:1, запрет молчаливой правки); фикстура inline-блока на месте"
