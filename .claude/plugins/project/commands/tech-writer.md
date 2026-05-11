---
description: "Tech Writer (subagent, Sonnet). Пишет/правит README, CHANGELOG, поля description в marketplace.json/plugin.json. Пример: /tech-writer update plugins/gramax, /tech-writer changelog 1.3.0"
allowed-tools: Task
---

Запусти subagent `tech-writer-agent` через Task tool.

**Входы пользователя:** `$ARGUMENTS`

## Что передать subagent'у

Сформируй prompt по контракту из AGENTS.md:

1. **Цель** одной фразой (обновить README плагина, выпустить CHANGELOG-запись, переписать `description` в манифесте).
2. **Входные файлы**:
   - Реализация плагина: `plugins/<name>/skills/`, `plugins/<name>/commands/`, `plugins/<name>/agents/`
   - Spec: `docs/superpowers/specs/<feature>.md` (для понимания JTBD и AC)
   - ADR: `docs/adr/NNNN-<slug>.md` (решения, которые надо отразить в CHANGELOG)
3. **Ожидаемый артефакт** — какие файлы редактируем:
   - Корневой `README.md` (обновление списка плагинов / badges)
   - `plugins/<name>/README.md` (детальная документация плагина)
   - Корневой `CHANGELOG.md` и/или `plugins/<name>/CHANGELOG.md` (формат Keep a Changelog: `## [version] - YYYY-MM-DD` + `Added/Changed/Fixed/Removed`)
   - Поле `description` в `plugins/<name>/.claude-plugin/plugin.json`
   - Поле `description` для каждого skill/command/agent в их frontmatter
   - Запись о плагине в корневом `.claude-plugin/marketplace.json` (`name`, `description`, `version`)
4. **Критерии приёмки**:
   - Тон — нейтральный технический, на русском
   - В README плагина: что делает, как установить, пример вызова, куда смотреть дальше
   - В `description` манифеста: 1-2 предложения, начинаются с глагола или существительного-задачи
   - В CHANGELOG: формат Keep a Changelog
   - Cross-ссылки рабочие (относительные пути)
   - Описания в frontmatter skill/command — главный источник, README пересказывает короче

## Режимы (распарсь $ARGUMENTS)

- `update <plugin>` — обновить README/описания плагина после новой фичи
- `changelog <version>` — выпустить запись в CHANGELOG
- `review <file>` — review документации на ясность и тон
- (свободный текст) — обсудить запрос
