# Acceptance Report — routing-mermaid-drawio-v2

**Date:** 2026-05-11
**Spec:** docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
**ADR:** docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md
**QA Report:** docs/qa-reports/2026-05-11-routing-mermaid-drawio.md
**Reviewer:** BA-agent (acceptance mode)

---

## Verdict

**ACCEPTED with notes**

Все 15 AC spec'а выполнены. QA-runner подтвердил 18/18 тестов зелёными. Три пост-merge задачи переданы Tech-writer'у и QA-author'у.

---

## AC mapping

| AC | Описание | Файл/строка-доказательство | Shell-проверка | Статус |
|----|----------|----------------------------|----------------|--------|
| AC-001 | `plugins/gramax/skills/drawio/SKILL.md` существует | `plugins/gramax/skills/drawio/SKILL.md` | `test -f` → PASS | ✅ |
| AC-002 | `plugin.json` объявляет skill `drawio` | `plugins/gramax/.claude-plugin/plugin.json:17` — `{"name": "drawio"}` | python3 assert → PASS | ✅ |
| AC-003 | description `gramax:drawio` содержит ключевые слова drawio | `SKILL.md:3` — description: «Только для drawio-диаграмм... нарисуй drawio...» | grep PASS | ✅ |
| AC-004 | `SKILL.md` содержит команду установки внешнего плагина | `plugins/gramax/skills/drawio/SKILL.md:25-26` — `/plugin marketplace add Agents365-ai/365-skills` + `/plugin install drawio` | grep -c → PASS | ✅ |
| AC-005 | `SKILL.md` содержит тег `[drawio:` (двухшаговый workflow) | `plugins/gramax/skills/drawio/SKILL.md:46` — `[drawio:./diagram.svg:Описание:800px:600px]` | grep -c → PASS | ✅ |
| AC-006 | `SKILL.md` содержит упоминание mermaid как альтернативы | `plugins/gramax/skills/drawio/SKILL.md:17,70-74` — cross-ref `gramax:mermaid`, Fallback-секция | grep -ic → PASS | ✅ |
| AC-007 | `mermaid/SKILL.md` не упоминает `mermaid-skill`/конфликт Agents365 | нет строк с `mermaid-skill` или `365-skills.*mermaid` | grep -c → 0 → PASS | ✅ |
| AC-008 | `mermaid/SKILL.md` содержит ссылку `gramax:drawio` | `plugins/gramax/skills/mermaid/SKILL.md:18,31,226` | grep -c → PASS | ✅ |
| AC-009 | `.gitmodules` не содержит `claude-mermaid` | `.gitmodules` отсутствует (`test ! -f` → PASS) | PASS | ✅ |
| AC-010 | `plugins/claude-mermaid/` отсутствует | директория не существует (`test ! -d` → PASS) | PASS | ✅ |
| AC-011 | `marketplace.json` не содержит активного entry `claude-mermaid` | `.claude-plugin/marketplace.json:11-17` — только `gramax` в `plugins[]` | python3 assert → PASS | ✅ |
| AC-012 | `plugin.json` содержит `"version": "3.0.0"` | `plugins/gramax/.claude-plugin/plugin.json:3` | python3 assert → PASS | ✅ |
| AC-013 | `CHANGELOG.md` содержит `## 3.0.0` и `### Migration` | `plugins/gramax/CHANGELOG.md:3,18` | grep -c → PASS | ✅ |
| AC-014 | `bash scripts/check.sh --fast` exit code 0 | whitespace OK, json OK, RESULT: PASS | shell → PASS | ✅ |
| AC-015 | `drawio/SKILL.md` не превышает 200 строк (прокси для ≤2000 токенов) | 85 строк, 415 слов | wc -l awk → PASS | ✅ |

**Итог: 15/15 AC — PASS.**

---

## NFR mapping

| NFR | Описание | Проверка | Результат |
|-----|----------|----------|-----------|
| NFR-001 | `drawio/SKILL.md` не более 2000 токенов (≈1500 слов) | `wc -w plugins/gramax/skills/drawio/SKILL.md` → 415 слов | ✅ Значительно ниже лимита |
| NFR-002 | Backward-compat для явных mermaid-запросов | `mermaid/SKILL.md` description содержит явные mermaid-ключевые слова: «mermaid», «flowchart», «sequence», «gantt»; поведение не изменилось | ✅ |
| NFR-003 | Breaking-compat для `claude-mermaid` MCP-preview — фиксируется в migration notes | `CHANGELOG.md:18-20` — миграция описана: удалить `mcpServers.mermaid`, использовать `gramax:mermaid` inline | ✅ |
| NFR-004 | `bash scripts/check.sh --fast` проходит без ошибок | Прямая проверка: whitespace OK, json OK, RESULT: PASS | ✅ |
| NFR-005 | Оба skill'а работают на macOS и Linux (bash 3.2+); внешние зависимости только у drawio | `mermaid/SKILL.md`: «Без внешних зависимостей и MCP»; `drawio/SKILL.md`: «Prerequisites» — внешний плагин | ✅ |
| NFR-006 | Description обоих skill'ов разграничивает движки на уровне ключевых слов | drawio description: «Только для drawio-диаграмм — НЕ для mermaid»; mermaid description: «Только для диаграмм в синтаксисе Mermaid DSL — НЕ для drawio» | ✅ |

---

## User stories — финальная проверка

| Story | Реализация | Статус |
|-------|------------|--------|
| Явный mermaid → `gramax:mermaid` | `mermaid/SKILL.md:3` description содержит «нарисуй mermaid», «mermaid-диаграмма», «flowchart mermaid» как явные триггеры | ✅ |
| Явный drawio (внешний плагин установлен) → `gramax:drawio` → двухшаговый workflow | `drawio/SKILL.md` секции «When to use» + «Workflow» — явный роутинг и описание Шаг 1 / Шаг 2 | ✅ |
| Явный drawio (внешний плагин НЕ установлен) → инструкция установки | `drawio/SKILL.md:20-26` — Prerequisites с точными командами `/plugin marketplace add` + `/plugin install drawio` | ✅ |
| Неявный «нарисуй диаграмму» → уточняющий вопрос | Fallback-секция в обоих `drawio/SKILL.md:66-79` и `mermaid/SKILL.md:22-33` — идентичный уточняющий вопрос с вариантами mermaid/drawio | ✅ |

---

## Замечания

1. **CHANGELOG 3.0.0 — минимален.** Секция присутствует со всеми обязательными подразделами (Added, Removed, Changed, Migration, ADR), однако Migration notes короткие относительно v2.0.0 (6 строк vs детальный список в 2.0.0). Tech-writer должен расширить до уровня v2.0.0: добавить нумерованные шаги, явные команды для обновления плагина (`/plugin update gramax`), уточнить что MCP-preview (`mermaid_preview`, `mermaid_save`) более недоступны.

2. **`CLAUDE.md` содержит orphan-строки** про `plugins/claude-mermaid/` как активный vendored submodule. Это техдолг из PR #4, не регрессия текущей фичи. QA-runner классифицировал как note. Tech-writer должен устранить в рамках этого же PR или отдельным фикс-коммитом.

3. **Тесты `remove-diagram-skills` (3 failing)** — не регрессии текущей фичи: хардкод версии `2.0.0` и regex в `ac-014`. QA-author должен обновить после merge.

4. **Тесты `diagram-on-demand` (11 failing)** — deprecated artifacts из PR #4. PM должен принять решение: пометить набор `[DEPRECATED]` или удалить. Не блокируют merge.

---

## Готовность к Tech-writer

Перед `/pm-review` Tech-writer должен выполнить:

1. **CHANGELOG 3.0.0 — расширить Migration notes:** добавить шаг `1. /plugin update gramax`, явное упоминание `mermaid_preview`/`mermaid_save` как недоступных инструментов, ссылку на ADR-0009 для пользователей, которые хотят понять обоснование.
2. **`CLAUDE.md` — убрать 3 строки** про `plugins/claude-mermaid/` как активный vendored submodule (строки в секции «Контекст проекта»). Заменить описанием актуальной архитектуры: один плагин `plugins/gramax/` с drawio-заглушкой.
3. **README плагина** — проверить, не упоминается ли `claude-mermaid` в `plugins/gramax/README.md`; при наличии — убрать или обновить.
4. **marketplace.json description** — опционально: уточнить поле `metadata.description` в `.claude-plugin/marketplace.json` под текущий scope (уже содержит drawio-delegation, но можно сделать более лаконичным).
