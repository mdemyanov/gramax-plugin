---
title: Архитектурные решения
order: 1
---

# Architecture Decision Records

Реестр архитектурных решений проекта `mdemyanov/gramax-plugin`.

Формат: `NNNN-<slug>.md`. Статусы: `Proposed` | `Accepted` | `Superseded by ADR-MMMM`.

При supersede — не изменяй старый ADR. Укажи «superseded в части X» только в новом ADR.

## Реестр

| ADR | Название | Статус | Дата | Плагин |
|-----|----------|--------|------|--------|
| [0001](0001-diagram-on-demand-plugin-split.md) | Размещение навыков diagram-on-demand внутри плагина gramax (без split) | Accepted → Superseded by ADR-0008 | 2026-05-08 | gramax / marketplace |
| [0002](0002-drawio-mcp-backend-selection.md) | Выбор drawio MCP-бэкенда и роль LLM в генерации XML | Accepted → Historical | 2026-05-08 | gramax |
| [0003](0003-drawio-backend-vendoring-strategy.md) | Vendoring strategy для drawio MCP-бэкенда | Accepted → Historical | 2026-05-08 | gramax |
| [0004](0004-router-and-engine-selection.md) | Механизм выбора движка (router и engine selection) | Accepted → Superseded by ADR-0008 | 2026-05-08 | gramax |
| [0005](0005-save-flow-script-api-contract.md) | Контракт API save flow (drawio_convert.py, slugify.py, .doc-root.yaml) | Accepted → Superseded by ADR-0008 | 2026-05-08 | gramax |
| [0006](0006-marketplace-json-semver-strategy.md) | Стратегия версионирования marketplace.json при добавлении diagram-on-demand | Accepted (Active) | 2026-05-08 | marketplace |
| [0007](0007-out-of-scope-phase2.md) | Функциональность, перенесённая в Phase 2 | Accepted → Superseded by ADR-0008 | 2026-05-08 | gramax |
| [0008](0008-drop-internal-drawio-skills.md) | Удаление внутренних drawio-skills и делегирование внешнему плагину | Accepted | 2026-05-11 | gramax / marketplace |
| [0009](0009-drawio-stub-and-claude-mermaid-removal.md) | Drawio-stub skill и удаление submodule claude-mermaid | Accepted | 2026-05-11 | gramax / marketplace |
| [0010](0010-mermaid-file-based-workflow.md) | Mermaid skill — file-based workflow | Accepted (дополнен ADR-0013) | 2026-05-12 | gramax |
| [0011](0011-test-harness-taxonomy.md) | Таксономия test harness tests/gramax и гейт doc-paths | Accepted | 2026-08-09 | gramax / marketplace |
| [0012](0012-catalog-validation-contract.md) | Контракт валидации Gramax-каталога как публичной поверхности плагина | Accepted (Решение 1 дополнено ADR-0015) | 2026-08-11 | gramax / marketplace |
| [0013](0013-mermaid-adoption-and-migration.md) | Принятие file-based mermaid потребителями и пакетная миграция | Accepted | 2026-08-11 | gramax |
| [0014](0014-dual-publication-targets.md) | Два независимых таргета публикации — публичный GitHub и внутренний GitLab-каталог | Accepted | 2026-08-11 | marketplace |
| [0015](0015-root-index-inert.md) | Корневой `_index.md` инертен для движка Gramax — амендмент к ADR-0012 Решение 1 | Accepted | 2026-08-11 | gramax / marketplace |
| [0016](0016-link-form-contract.md) | Контракт формы ссылки на артефакт — резолвер гейта и временный протокол при расхождении с nauta | Accepted (дополнен ADR-0018) | 2026-08-13 | gramax / marketplace |
| [0017](0017-cross-catalog-retraction.md) | Ретракция нерабочего рецепта cross-каталожной ссылки через `code` — амендмент к диспозиции Тема A/FR-065 | Accepted | 2026-08-13 | gramax / marketplace |
| [0018](0018-link-form-version-authorization.md) | Резервирование версии 4.3.0 волны link-form-contract и разрешение на синхронную правку marketplace.json | Accepted | 2026-08-12 | gramax / marketplace |
| [0019](0019-render-killer-linter.md) | Линтер рендер-киллеров (порт validate-gramax.py) — отдельный контент-валидатор, гибридный контракт, демаркация с W034 | Accepted | 2026-08-12 | gramax / marketplace |
| [0020](0020-doc-root-recursive-discovery.md) | Рекурсивное обнаружение .doc-root.yaml и типизация обязательных полей в validate_structure.py | Accepted | 2026-08-13 | gramax / marketplace |

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
