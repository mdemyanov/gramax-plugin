# ADR-0001: Размещение навыков diagram-on-demand внутри плагина gramax (без split)

**Status:** Superseded by ADR-0008
**Date:** 2026-05-08
**Plugin:** gramax / marketplace

## Context

Spec `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` вводит два движка генерации диаграмм: mermaid и drawio. Open question #1 из spec: нужен ли split на два отдельных плагина (`diagram-mermaid` + `diagram-drawio`) или оба движка живут внутри одного плагина.

Текущее состояние репозитория:
- `plugins/gramax/` — основной плагин с skills writer, comments-read, comments-write, diagrams.
- `plugins/claude-mermaid/` — vendored git submodule (veelenga/claude-mermaid, MIT), предоставляет MCP-сервер для mermaid live-preview.
- Общие скрипты (`drawio_convert.py`, `slugify.py`) живут в `plugins/gramax/scripts/`.
- Корневой `marketplace.json` содержит два entry: `gramax` и `claude-mermaid`.

Два кандидата:

**Вариант A — два новых плагина** (`diagram-mermaid`, `diagram-drawio`):
- Каждый плагин независим, имеет свой `plugin.json` с `mcpServers`.
- Пользователь подключает только нужный движок.
- Требует дублирования доступа к `drawio_convert.py` / `slugify.py` (скрипты живут в `gramax`), либо выноса скриптов в третий shared-плагин.
- Два новых entry в `marketplace.json` — breaking change в смысле ожиданий пользователей.
- Router-skill (где живёт диспетчеризация между движками?) нужен третий артефакт.

**Вариант B — один skill `diagram-on-demand` внутри `gramax`**:
- Skill добавляется в `plugins/gramax/skills/diagram-on-demand/SKILL.md`.
- Общие скрипты доступны через `${CLAUDE_PLUGIN_ROOT}/scripts/` без дублирования.
- `mcpServers` для mermaid уже решён через vendored `claude-mermaid` (используется как есть).
- `mcpServers` для опционального drawio MCP добавляется в `plugins/gramax/.claude-plugin/plugin.json`.
- Один entry в `marketplace.json` не меняется.
- Токен-бюджет skill делится на оба пути; NFR-002 (≤2000 токенов) требует строгой структуры.

## Decision

Оба движка реализуются как один skill `diagram-on-demand` внутри существующего плагина **`gramax`**.

Аргументы:
1. **Shared scripts.** `drawio_convert.py` и `slugify.py` уже в `plugins/gramax/scripts/`. Переносить или дублировать ради split — преждевременное усложнение.
2. **MCP уже решён для mermaid.** `claude-mermaid` submodule предоставляет mermaid MCP; skill в `gramax` просто объявляет его использование. Нет причины заводить новый плагин `diagram-mermaid` поверх уже работающего механизма.
3. **Router не нужен как отдельный артефакт.** Пользователь явно называет движок; skill извлекает параметр `engine` из запроса. Диспетчеризация — часть skill-промпта, не отдельного router-skill.
4. **marketplace.json без изменений.** Нет нового entry, нет bump major-версии.
5. **Независимое тестирование путей.** Два кода пути (mermaid / drawio) тестируются через отдельные smoke-тесты; split плагина для этого не требуется.

Ограничение: единый skill должен уложиться в ≤2000 токенов (NFR-002). Для этого оба пути описываются компактно; детали реализации вынесены в `references/`.

## Consequences

**Положительные:**
- Нет изменений в `marketplace.json` — пользователи не замечают структурного сдвига.
- Общие скрипты доступны без дублирования.
- Меньше артефактов для поддержки (один `plugin.json`, один SKILL.md).

**Отрицательные / trade-offs:**
- Skill `diagram-on-demand` содержит логику двух движков — нарушает «одна ответственность».
- `plugin.json` плагина `gramax` расширяется секцией `mcpServers` (новое поле).
- Если в будущем появится третий движок, skill разрастётся.

**Открытые риски:**
- Токен-бюджет ≤2000 под давлением: при добавлении третьего движка или расширении edge cases может понадобиться split на тот момент.

**Mitigations:**
- Детали каждого движка выносятся в `references/mermaid-path.md` и `references/drawio-path.md` — skill-промпт ссылается на них, не дублирует.
- При добавлении третьего движка — пересмотр split в новом ADR.

## Alternatives Considered

- **Два отдельных плагина `diagram-mermaid` / `diagram-drawio`** — отклонено: требует дублирования shared scripts или введения третьего shared-плагина; два новых entry в `marketplace.json`; router-skill без домашнего плагина.
- **Один плагин `diagram-studio` (новый, отдельный от gramax)** — отклонено: дублирует скрипты, требует нового entry в `marketplace.json`, не даёт преимуществ перед вариантом B.

## Связанные артефакты

- spec: `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` (open question #1)
- затрагивает: `plugins/gramax/.claude-plugin/plugin.json`, `plugins/gramax/skills/diagram-on-demand/SKILL.md`
- см. также: ADR-0004 (router и engine selection), ADR-0006 (marketplace.json semver)
