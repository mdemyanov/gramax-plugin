# Architecture Decision Records

Реестр архитектурных решений проекта `mdemyanov/gramax-plugin`.

Формат: `NNNN-<slug>.md`. Статусы: `Proposed` | `Accepted` | `Superseded by ADR-MMMM`.

При supersede — не изменяй старый ADR. Укажи «superseded в части X» только в новом ADR.

## Реестр

| ADR | Название | Статус | Дата | Плагин |
|-----|----------|--------|------|--------|
| [0001](0001-diagram-on-demand-plugin-split.md) | Размещение навыков diagram-on-demand внутри плагина gramax (без split) | Accepted | 2026-05-08 | gramax / marketplace |
| [0002](0002-drawio-mcp-backend-selection.md) | Выбор drawio MCP-бэкенда и роль LLM в генерации XML | Accepted | 2026-05-08 | gramax |
| [0003](0003-drawio-backend-vendoring-strategy.md) | Vendoring strategy для drawio MCP-бэкенда | Accepted | 2026-05-08 | gramax |
| [0004](0004-router-and-engine-selection.md) | Механизм выбора движка (router и engine selection) | Accepted | 2026-05-08 | gramax |
| [0005](0005-save-flow-script-api-contract.md) | Контракт API save flow (drawio_convert.py, slugify.py, .doc-root.yaml) | Accepted | 2026-05-08 | gramax |
| [0006](0006-marketplace-json-semver-strategy.md) | Стратегия версионирования marketplace.json при добавлении diagram-on-demand | Accepted | 2026-05-08 | marketplace |
| [0007](0007-out-of-scope-phase2.md) | Функциональность, перенесённая в Phase 2 | Accepted | 2026-05-08 | gramax |

## Связи между ADR

```
ADR-0001 (no split)
  ├── → ADR-0004 (один skill, внутренний router)
  └── → ADR-0006 (нет новых entry в marketplace.json)

ADR-0002 (drawio MCP = optional, lgazo как рекомендованный)
  ├── → ADR-0003 (vendoring = docs only + mcpServers decl)
  └── → ADR-0007 (полный SVG-рендер = Phase 2)

ADR-0005 (save flow contract)
  ├── переиспользует: drawio_convert.py, slugify.py
  └── вводит новый: find_doc_root.sh
```
