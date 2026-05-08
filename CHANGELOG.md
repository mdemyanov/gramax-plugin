# Marketplace Changelog

## 1.0.0 — 2026-05-08

Первый релиз публичного marketplace репо `mdemyanov/gramax-plugin`.

### Plugins
- `gramax` v1.2.0 — основной плагин (миграция из `mdemyanov/ai-assistants/plugins/gramax/`). Новое: skill `diagrams`, agent `review-agent`.
- `claude-mermaid` (vendored) — git submodule на upstream `veelenga/claude-mermaid` (MIT).

### Структура
- Корень репо — Claude Code marketplace (`.claude-plugin/marketplace.json`).
- `plugins/gramax/` — наш плагин с собственной версионностью.
- `plugins/claude-mermaid/` — submodule стороннего MIT-плагина.
