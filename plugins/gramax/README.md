# Gramax Plugin

Claude Code plugin для работы с документацией в формате Gramax.

## Установка

```
/plugin marketplace add mdemyanov/gramax-plugin
/plugin install gramax@gramax-marketplace
```

## Skills

- `/gramax:writer` — создание и редактирование Gramax-документов
- `/gramax:comments-read <path>` — показать комментарии документа
- `/gramax:comments-write <path>` — добавить/ответить/редактировать/удалить комментарий
- `/gramax:mermaid` — генерация mermaid-диаграмм по описанию inline, без MCP и внешних зависимостей

### Skill `mermaid`

Генерирует mermaid DSL по словесному описанию и (опционально) вставляет блок в md-страницу Gramax-каталога. Полностью inline — без MCP-серверов, без скриптов, без preview.

Триггеры: «нарисуй mermaid», «сгенерируй mermaid-диаграмму», «визуализируй процесс/архитектуру/цикл», «сделай flowchart/sequence/gantt/class/state/ER/pie/mindmap».

Поддерживаемые типы: `flowchart`, `sequenceDiagram`, `gantt`, `classDiagram`, `stateDiagram-v2`, `erDiagram`, `pie`, `mindmap`.

Адаптировано из [axtonliu/axton-obsidian-visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills) (MIT) — см. `skills/mermaid/LICENSE.upstream.md`.

## Drawio (внешний плагин)

Drawio-функциональность делегирована стороннему плагину `Agents365-ai/drawio-skill`. Локальных скриптов для drawio в плагине больше нет.

### Prerequisites

**draw.io desktop** (требуется внешнему плагину для конвертации):

- macOS: `brew install --cask drawio`
- Windows / Linux: [github.com/jgraph/drawio-desktop/releases](https://github.com/jgraph/drawio-desktop/releases)
  - Linux: скачивай `.deb` или `.rpm`. **Не используй snap** — AppArmor блокирует запись файлов.

**Python 3** (нужен для `repair_png.py` внутри плагина drawio-skill):

Должен быть установлен и доступен в PATH.

**Установка плагина:**

```
/plugin marketplace add Agents365-ai/365-skills
/plugin install drawio
```

> **Warning:** Не устанавливай `Agents365-ai/mermaid-skill` параллельно с `gramax:mermaid` — конфликт триггеров.

Детали workflow и Gramax-теги для вставки — в справочнике writer-skill (файл `references/drawio.md`).

## Agents

- `review-agent` — координирует ревью комментариев в каталоге (запуск через Task tool)

## Scripts

Скрипты в `scripts/` доступны через `${CLAUDE_PLUGIN_ROOT}/scripts/...`:

- `slugify.py` — транслит кириллицы в latin-slug для имён файлов
- `validate_structure.py` — pre-publish валидация каталога Gramax
- `parse_comments.py` — парсинг и отчёт по комментариям
- `gen_comment_id.py` — генерация уникального ID комментария
- `validate_comments.py` — валидация парности `<comment>` ↔ `.comments.yaml`

## Версия

2.0.0 — см. [CHANGELOG.md](./CHANGELOG.md)
