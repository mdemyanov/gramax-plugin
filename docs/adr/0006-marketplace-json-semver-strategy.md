# ADR-0006: Стратегия версионирования marketplace.json при добавлении diagram-on-demand

**Status:** Accepted
**Date:** 2026-05-08
**Plugin:** marketplace

## Context

Корневой `.claude-plugin/marketplace.json` — публичный договор с пользователями плагина `mdemyanov/gramax-plugin`. Текущее состояние: `metadata.version: "1.0.0"`, два entry (`gramax`, `claude-mermaid`).

Фича `diagram-on-demand` добавляет новый skill в существующий плагин `gramax` (ADR-0001: split отклонён, новых entry нет).

Open question: нужен ли bump версии в `marketplace.json` при добавлении функциональности в существующий плагин?

Semver-семантика в контексте marketplace:
- **Patch (1.0.x)** — bug fix, исправление описания, изменение `source` пути без изменения функциональности.
- **Minor (1.x.0)** — additive change: новый skill, новая команда, новый agent внутри существующего плагина; новый опциональный MCP-сервер в `plugin.json`.
- **Major (x.0.0)** — breaking change: переименование плагина, удаление skill, несовместимое изменение `mcpServers`, смена структуры `marketplace.json`.

Добавление `diagram-on-demand` skill:
- Новый skill `diagram-on-demand` в `plugins/gramax/skills/` — additive, не ломает существующих пользователей.
- Новая секция `mcpServers` в `plugins/gramax/.claude-plugin/plugin.json` — additive, опциональна (MCP-бэкенд не обязателен).
- Entry `gramax` в `marketplace.json` остаётся без изменений (source, name).
- Описание `description` в marketplace entry может быть обновлено для упоминания нового skill.

**Вывод:** изменение является additive minor — новая функциональность без удаления или изменения существующей.

## Decision

При выпуске `diagram-on-demand` в `main`:

1. **`metadata.version` в `.claude-plugin/marketplace.json`** — bump до `1.1.0` (minor, additive).
2. **`version` в `plugins/gramax/.claude-plugin/plugin.json`** — bump `1.2.0` → `1.3.0` (minor).
3. **`description` в marketplace entry `gramax`** — обновить для упоминания `diagram-on-demand`. Это additive изменение описания, не breaking.
4. **Новых entry в `marketplace.json`** — не добавляется (ADR-0001: split отклонён).

Bump выполняется Tech-writer как часть release-flow, после Dev + QA-runner (зелёный smoke).

Bump `marketplace.json` не является breaking change. ADR требуется не потому что breaking, а потому что `marketplace.json` — публичный контракт: любое изменение должно быть задокументировано (конвенция из CLAUDE.md).

Если бы фича требовала новых entry в `marketplace.json` (при split плагина) — это была бы более значимая операция, требующая явного PM sign-off. В данном случае (только bump описания + minor version) PM sign-off не требуется.

## Consequences

**Положительные:**
- Пользователи, установившие `gramax@1.x`, получают обновление без breaking changes.
- Bump minor сигнализирует: «новая функциональность доступна».
- Структура `marketplace.json` не меняется — нет риска поломки инсталляций.

**Отрицательные / trade-offs:**
- Bump `marketplace.json` и `plugin.json` — два файла, которые Tech-writer должен обновить синхронно.
- При несинхронизированном bump (один файл обновлён, другой нет) — версии расходятся. Mitigation: checklist в `/pm-review`.

**Открытые риски:**
- Если `mcpServers` в `plugin.json` окажется breaking (изменяет конфиг существующих пользователей) — потребует major bump. Mitigation: `mcpServers` — опциональный, не замещает существующие MCP-конфиги пользователя.

## Alternatives Considered

- **Только patch bump (1.0.1)** — отклонено: новый skill — это новая функциональность, не bug fix; patch семантически неверен.
- **Major bump (2.0.0)** — отклонено: изменение не breaking; major создаст ложное ощущение несовместимости.
- **Не менять версию marketplace.json** — отклонено: `marketplace.json` является публичным контрактом; любое функциональное изменение должно быть отражено в версии для reproducible installs.

## Связанные артефакты

- spec: `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md`
- предшествует: ADR-0001 (нет новых entry)
- затрагивает: `.claude-plugin/marketplace.json`, `plugins/gramax/.claude-plugin/plugin.json`, `plugins/gramax/CHANGELOG.md`
