---
description: "Системный аналитик (subagent, Sonnet). Архитектура плагина, ADR, границы skill/command/agent. Пример: /sa design <фича>, /sa adr <решение>, /sa review docs/adr/0003-foo.md"
allowed-tools: Task
---

Запусти subagent `project:sa-agent` через Task tool (`subagent_type: "project:sa-agent"`).

**Входы пользователя:** `$ARGUMENTS`

## Что передать subagent'у

Сформируй prompt по контракту из AGENTS.md:

1. **Цель** одной фразой (что спроектировать/решить/проверить).
2. **Входные файлы**:
   - BA spec: `docs/superpowers/specs/<file>.md`
   - Существующие ADR: `docs/adr/`
   - Реализация плагинов: `plugins/<name>/`
   - Корневой манифест: `.claude-plugin/marketplace.json`
   - Манифест плагина: `plugins/<name>/.claude-plugin/plugin.json`
3. **Ожидаемый артефакт** — путь `docs/adr/NNNN-<slug>.md` (формат MADR / Nygard).
4. **Критерии приёмки**:
   - Границы единиц плагина (skill vs command vs agent) обоснованы
   - NFR mapping (как требования из BA закрываются)
   - Если затронут публичный manifest или новый submodule — ADR обязателен
   - Alternatives considered и consequences описаны
   - Совместимость: с какими версиями Claude Code тестировалось / поддерживается

## Триггеры обязательного ADR

| Ситуация | Почему ADR обязателен |
|----------|------------------------|
| Новая фича плагина (skill/command/agent), не описанная ранее | Закрепить границы и тон |
| Новый плагин в `plugins/<name>/` | Меняется публичный `marketplace.json` |
| Новый git submodule (вендоринг) | Договор с upstream, лицензионные нюансы |
| Breaking change в `marketplace.json` или `plugin.json` (rename, remove, bump major) | Влияет на пользователей |

## Режимы (распарсь $ARGUMENTS)

- `design <фича>` — архитектурный дизайн фичи (skill/command/agent + ADR при необходимости)
- `adr <решение>` — оформить ADR в `docs/adr/NNNN-<slug>.md`
- `review <path>` — ревью архитектурного артефакта или ADR
- (свободный текст) — обсудить вопрос
