# Marketplace Changelog

## 3.0.0 — 2026-05-11

Breaking change. Устранён конфликт триггеров mermaid/drawio: добавлен явный skill `gramax:drawio`, удалён vendored mermaid-preview submodule из marketplace.

### Added
- `gramax` v3.0.0: skill `gramax:drawio` — заглушка-делегатор на внешний `Agents365-ai/drawio-skill`. Описывает двухшаговый Gramax-workflow и команды установки внешнего плагина.

### Removed
- Vendored mermaid-preview submodule удалён из marketplace и репозитория. MCP-инструменты `mermaid_preview`/`mermaid_save` более недоступны. Запись удалена из `.claude-plugin/marketplace.json`.

### Changed
- `gramax:mermaid` description уточнён: добавлены generic-триггеры и cross-ref на `gramax:drawio`; добавлена секция Fallback при неоднозначном запросе.
- `marketplace.json` и `plugin.json` — version `3.0.0`, descriptions обновлены.

### Migration

Пользователям v2.x — три действия:
1. Удалить запись `mcpServers.mermaid` из `~/.claude/settings.json` (если есть).
2. Установить `Agents365-ai/drawio-skill` для drawio-диаграмм (`/plugin marketplace add Agents365-ai/365-skills && /plugin install drawio`).
3. MCP-preview mermaid больше не поддерживается — используй `gramax:mermaid` inline.

Подробные шаги и known limitations — в [`plugins/gramax/CHANGELOG.md § 3.0.0`](./plugins/gramax/CHANGELOG.md).

## 2.0.0 — 2026-05-11

### Changed
- `gramax` обновлён до v2.0.0: удалены внутренние diagram-skills, drawio делегирован внешнему плагину.

## 1.2.0 — 2026-05-08

### Changed
- `gramax` обновлён до v1.4.0: добавлен skill `mermaid` — генерация mermaid-диаграмм по описанию inline (без MCP). Адаптирован из upstream `axtonliu/axton-obsidian-visual-skills` (MIT).

## 1.1.0 — 2026-05-08

### Changed
- `gramax` обновлён до v1.3.0: добавлен skill `diagram-on-demand` — явная генерация mermaid/drawio по описанию с сохранением в Gramax-каталог.

## 1.0.0 — 2026-05-08

Первый релиз публичного marketplace репо `mdemyanov/gramax-plugin`.

### Plugins
- `gramax` v1.2.0 — основной плагин (миграция из `mdemyanov/ai-assistants/plugins/gramax/`). Новое: skill `diagrams`, agent `review-agent`.
- Vendored mermaid-preview plugin — git submodule (MIT). Удалён в v3.0.0 (ADR-0009).

### Структура
- Корень репо — Claude Code marketplace (`.claude-plugin/marketplace.json`).
- `plugins/gramax/` — наш плагин с собственной версионностью.
