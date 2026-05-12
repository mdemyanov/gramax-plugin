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
- `/gramax:mermaid` — генерация mermaid-диаграмм: создаёт `.mermaid`-файл рядом со статьёй и вставляет тег-ссылку в md
- `/gramax:drawio` — drawio-диаграммы через внешний плагин `Agents365-ai/drawio-skill` (двухшаговый workflow)

### Skill `mermaid`

Генерирует mermaid DSL по словесному описанию, записывает его в отдельный `.mermaid`-файл рядом со статьёй и вставляет тег-ссылку `<mermaid path="…"/>` в md-документ. Без MCP-серверов и внешних зависимостей.

Триггеры: «нарисуй mermaid», «сгенерируй mermaid-диаграмму», «визуализируй процесс/архитектуру/цикл», «сделай flowchart/sequence/gantt/class/state/ER/pie/mindmap».

При запросе без явного движка («нарисуй диаграмму») задаёт уточняющий вопрос: mermaid (`.mermaid`-файл + тег-ссылка) или drawio (через внешний плагин, создаёт `.svg`).

**Пример результата:** для статьи `docs/auth/overview.md` с темой «процесс авторизации» skill создаёт `docs/auth/overview-auth-flow.mermaid` и вставляет в md тег `<mermaid path="./overview-auth-flow.mermaid" width="800px" height="450px"/>`.

Поддерживаемые типы: `flowchart`, `sequenceDiagram`, `gantt`, `classDiagram`, `stateDiagram-v2`, `erDiagram`, `pie`, `mindmap`.

Адаптировано из [axtonliu/axton-obsidian-visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills) (MIT) — см. `skills/mermaid/LICENSE.upstream.md`.

### Skill `drawio`

Точка входа для явных drawio-запросов («нарисуй drawio», «drawio-схема», «.drawio-файл»). Не генерирует диаграммы самостоятельно — делегирует на внешний `Agents365-ai/drawio-skill` и описывает двухшаговый Gramax-workflow:

- Шаг 1: drawio-skill создаёт `.drawio` + `.svg` в рабочей директории.
- Шаг 2: вставь тег в md-страницу (writer-skill подскажет формат): `[drawio:./diagram.svg:Описание:800px:600px]`.

**Установка внешнего плагина:**

```
/plugin marketplace add Agents365-ai/365-skills
/plugin install drawio
```

**Дополнительные зависимости** (требуются внешнему плагину):

- **draw.io desktop**: macOS — `brew install --cask drawio`; Linux — `.deb`/`.rpm` с [releases](https://github.com/jgraph/drawio-desktop/releases) (не используй snap — AppArmor блокирует запись файлов).
- **Python 3** — нужен для `repair_png.py` внутри drawio-skill; должен быть в PATH.

Детали Gramax-тегов для вставки — в справочнике writer-skill (файл `references/drawio.md`).

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

4.0.0 — см. [CHANGELOG.md](./CHANGELOG.md)
