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
- Шаг 2: вставь тег в md-страницу (writer-skill подскажет формат): `<drawio path="./diagram.svg" width="800px" height="600px"/>`.

**Установка внешнего плагина:**

```
/plugin marketplace add Agents365-ai/365-skills
/plugin install drawio
```

> **Warning:** Не устанавливайте `Agents365-ai/mermaid-skill` из 365-skills одновременно
> с `gramax:mermaid`. Оба skill'а описывают одинаковые триггеры (flowchart, sequence,
> gantt и др.) — Claude может выбрать не тот, поведение становится недетерминированным.
> Для drawio устанавливайте только `drawio` из 365-skills (не `mermaid`).

**Дополнительные зависимости** (требуются внешнему плагину):

- **draw.io desktop**: macOS — `brew install --cask drawio`; Linux — `.deb`/`.rpm` с [releases](https://github.com/jgraph/drawio-desktop/releases) (не используй snap — AppArmor блокирует запись файлов).
- **Python 3** — нужен для `repair_png.py` внутри drawio-skill; должен быть в PATH.

Детали Gramax-тегов для вставки — в справочнике writer-skill (файл `references/drawio.md`).

## Валидация каталога

Плагин поставляет `scripts/validate_structure.py` — офлайн pre-publish валидатор
Gramax-каталога (обязательность `_index.md` в подпапках, парность тегов, frontmatter,
плейсхолдеры `{{ИМЯ}}`, статьи-сироты, битые markdown-ссылки). Правила и список
поддерживаемых Gramax-тегов — не в прозе, а в двух машиночитаемых JSON-контрактах рядом со
скриптом: [`gramax-tags.json`](./gramax-tags.json) и
[`gramax-catalog-rules.json`](./gramax-catalog-rules.json) — единственный источник правды,
который сам валидатор читает при каждом запуске (ADR-0012). Для подключения к pre-commit/CI
своего репозитория скопируйте готовый шаблон
[`scripts/pre-commit.sh`](./scripts/pre-commit.sh).

```bash
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py" content
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py" --help
```

Второй валидатор — `scripts/validate_render.py`: контент-линтер рендер-киллеров
(порт `validate-gramax.py`, MIT). Ловит конструкции, роняющие рендерер GES с HTTP 500
или ломающие вёрстку, на уровне ERROR с номером строки и подсказкой: `<th>`, инлайновый
`<note>…</note>`, `<note>` внутри `<td>`/`<th>`, `<note>` в `<note>`, несколько `![](…)`
в строке, несбалансированные парные теги (`note/table/tr/td/th/tabs/tab/color/highlight`).
Стиль/YAML (`# H1` в теле, frontmatter `title:` без кавычек) — WARN и exit не меняют.
Код (fenced **+ inline**) исключается из проверок — примеры синтаксиса в прозе не
считаются разметкой. Реестр киллеров/баланса/allowlist — машиночитаемый контракт
[`gramax-render-rules.json`](./gramax-render-rules.json) (ADR-0019). Атрибуция источника —
[`scripts/LICENSE.upstream.md`](./scripts/LICENSE.upstream.md).

```bash
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_render.py" content
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_render.py" --help
```

Pre-commit-хук этого плагина запускает оба валидатора (структурный + контент-линтер):
киллер рендера блокирует коммит, WARN-стиль через `--errors-only` не спамит.

Отдельно — `scripts/migrate_mermaid.py`: офлайн-сканер и пакетный мигратор устаревшего inline-mermaid (`<mermaid>…</mermaid>`, fenced ` ```mermaid `) в file-based формат внутри границы юрисдикции (`.doc-root.yaml`). По умолчанию — только отчёт (файл:строка + сводка из трёх счётчиков — `To-migrate`/`Out-of-jurisdiction`/`Already-compliant`), без единой мутации; мутация — только под `--fix --yes` (сводка тогда печатает `Migrated` вместо `To-migrate`). **Режим отчёта завершается ненулевым кодом, если найдены вхождения для миграции** — удобно как сигнал для CI, но учтите это заранее при вставке вызова в свой пайплайн, не выясняйте по красной сборке. Граница юрисдикции и предикат валидного `.mermaid`-файла для собственного валидатора потребителя — [`skills/mermaid/references/jurisdiction-and-validation.md`](./skills/mermaid/references/jurisdiction-and-validation.md).

```bash
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/migrate_mermaid.py" content
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/migrate_mermaid.py" content --fix --yes
```

## Agents

- `review-agent` — координирует ревью комментариев в каталоге (запуск через Task tool)

## Scripts

Скрипты в `scripts/` доступны через `${CLAUDE_PLUGIN_ROOT}/scripts/...`:

- `slugify.py` — транслит кириллицы в latin-slug для имён файлов
- `validate_structure.py` — pre-publish валидация структуры каталога Gramax
- `validate_render.py` — контент-линтер рендер-киллеров (порт validate-gramax.py, MIT)
- `parse_comments.py` — парсинг и отчёт по комментариям
- `gen_comment_id.py` — генерация уникального ID комментария
- `validate_comments.py` — валидация парности `<comment>` ↔ `.comments.yaml`

## Версия

4.4.0 — см. [CHANGELOG.md](./CHANGELOG.md)
