# ADR-0003: Vendoring strategy для drawio MCP-бэкенда

**Status:** Accepted
**Date:** 2026-05-08
**Plugin:** gramax

## Context

Spec open question #2 (часть): как доставить drawio MCP-бэкенд конечному пользователю плагина?

ADR-0002 постановил, что drawio MCP-бэкенд не является обязательной зависимостью MVP. Тем не менее, `plugin.json` должен описывать как подключить MCP для пользователей, желающих расширенного рендеринга. Нужно выбрать стратегию.

Кандидаты:
1. **Git submodule** (аналогично `claude-mermaid`): репозиторий бэкенда добавляется как submodule в `plugins/gramax/vendor/drawio-mcp/`.
2. **npm/pip dependency** с явным `install`-шагом в README / `plugin.json`.
3. **Bash-обёртка** скачивания бинарника или `npm install` при первом запуске.
4. **Только документация**: README объясняет, что установить вручную; `mcpServers` в `plugin.json` описывает конфиг.

Контекст выбора:
- `claude-mermaid` — git submodule, потому что это законченный плагин сам по себе (MCP + skills), и мы хотим следить за upstream.
- drawio MCP-бэкенд — это сторонний инструмент, который пользователь запускает как MCP-сервер; он не является частью нашего плагина.
- Claude Code `mcpServers` конфигурация в `plugin.json` — стандартный способ декларировать MCP-серверы; пользователь устанавливает их сам.
- NFR-004: скрипты не зависят от сторонних пакетов за пределами stdlib. Bash-обёртка с `npm install` нарушает этот принцип в контексте выполнения скриптов.
- UX onboarding: Claude Code показывает `mcpServers` из `plugin.json` и предлагает установку; пользователь решает сам.

## Decision

**Стратегия: только документация + декларативный `mcpServers` в `plugin.json`.**

`plugin.json` плагина `gramax` объявляет опциональную секцию `mcpServers` с конфигурацией для `lgazo/drawio-mcp-server`:

```json
{
  "mcpServers": {
    "drawio": {
      "command": "npx",
      "args": ["-y", "@lgazo/drawio-mcp-server"],
      "description": "Опциональный MCP-сервер для расширенного drawio SVG-рендеринга. Требует Node.js 18+. Без него skill использует встроенный drawio_convert.py."
    }
  }
}
```

README плагина добавляет раздел «Drawio MCP (опционально)» с инструкцией установки.

Не используем git submodule, потому что:
- drawio MCP-бэкенд не является частью нашего плагина; мы его не патчим и не контролируем.
- submodule подразумевает, что мы отслеживаем upstream и принимаем ответственность за обновления — для optional tool это избыточно.
- `claude-mermaid` был добавлен как submodule, потому что содержит сам skill (skills/mermaid-diagrams/SKILL.md) — это наш контент. drawio MCP — только инструмент.

Не используем bash-обёртку скачивания, потому что:
- Автоматическое выполнение `npm install` без явного consent пользователя — плохой UX и security antipattern.
- Claude Code механизм `mcpServers` уже решает эту задачу декларативно.

## Consequences

**Положительные:**
- Нет новых submodule в репозитории; структура остаётся чистой.
- Пользователь контролирует установку MCP-бэкенда самостоятельно.
- Полная совместимость с Claude Code `mcpServers` механизмом.
- MVP работает без MCP (через `drawio_convert.py`) — onboarding friction = 0.

**Отрицательные / trade-offs:**
- Пользователь, желающий полного SVG-рендера, делает ручной шаг установки Node.js + `npx`.
- Нет автоматической проверки версии `lgazo/drawio-mcp-server` — пользователь получает latest.

**Открытые риски:**
- Upstream `lgazo/drawio-mcp-server` может изменить transport или tool-names — нарушит конфиг в `plugin.json`. Mitigation: зафиксировать версию в `args` (`@lgazo/drawio-mcp-server@2.1.0`).

**Mitigations:**
- Зафиксировать конкретную версию пакета в `args` (`@lgazo/drawio-mcp-server@2.1.0`).
- В skill-промпте описать поведение при отсутствии MCP (FR-011, AC-009) — пользователь не застревает.

## Alternatives Considered

- **Git submodule** — отклонено: drawio MCP — не наш контент, мы его не патчим; submodule добавляет overhead без пользы.
- **npm/pip dependency с install-шагом в CI** — отклонено: у нас нет CI для конечных пользователей; каждый устанавливает плагин через `git clone`.
- **Bash-обёртка `auto-install.sh`** — отклонено: скрытый `npm install` без consent — security antipattern; нарушает NFR-004 в духе (хотя технически не stdlib-dep).

## Связанные артефакты

- spec: `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` (FR-011, AC-009)
- предшествует: ADR-0002 (выбор drawio MCP-бэкенда)
- затрагивает: `plugins/gramax/.claude-plugin/plugin.json`, `plugins/gramax/README.md`
