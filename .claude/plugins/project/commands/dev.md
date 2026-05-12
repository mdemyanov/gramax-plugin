---
description: "Разработчик (subagent, Sonnet). TDD-реализация фичи плагина (shell/JS/markdown skills) по spec и ADR. Пример: /dev implement <фича>, /dev fix <bug>, /dev refactor <путь>"
allowed-tools: Task
---

Запусти subagent `project:dev-agent` через Task tool (`subagent_type: "project:dev-agent"`).

**Входы пользователя:** `$ARGUMENTS`

## Что передать subagent'у

Сформируй prompt по контракту из AGENTS.md:

1. **Цель** одной фразой.
2. **Входные файлы**:
   - Spec (для AC): `docs/superpowers/specs/<file>.md`
   - ADR (если применимо): `docs/adr/NNNN-<slug>.md`
   - Failing test stubs от QA-author: `tests/<plugin>/<feature>_test.sh`
   - Существующая реализация плагина: `plugins/<name>/`
3. **Ожидаемый артефакт**:
   - Код фичи в `plugins/<name>/skills/<feature>/`, `plugins/<name>/commands/`, `plugins/<name>/agents/`, `plugins/<name>/scripts/`
   - Тесты (зелёные) в `tests/<plugin>/<feature>_test.sh`
   - Обновлённые манифесты `plugins/<name>/.claude-plugin/plugin.json` (и опц. `.claude-plugin/marketplace.json` если ADR разрешил)
4. **Критерии приёмки**:
   - Все Acceptance Criteria из spec'а покрыты тестами
   - `bash tests/<plugin>/run.sh` зелёный перед commit (показать вывод)
   - Соблюдён TDD-цикл (red → green → refactor → commit)
   - Markdown-skills проходят self-test (frontmatter валиден, описание триггерит)
   - JSON-манифесты валидны (`jq . < plugin.json`)

## Режимы (распарсь $ARGUMENTS)

- `implement <фича>` — реализация по spec + ADR (TDD на shell/JS/markdown)
- `fix <bug>` — багфикс через `superpowers:systematic-debugging`
- `test <модуль>` — добавить покрытие в `tests/<plugin>/`
- `refactor <путь>` — рефакторинг с зелёными тестами
- (свободный текст) — обсудить
