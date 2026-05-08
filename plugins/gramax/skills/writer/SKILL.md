---
name: writer
description: Создание и редактирование документации Gramax (markdown с XML-расширениями). Используй когда пользователь работает с Gramax-каталогом, создаёт/редактирует статьи, добавляет .doc-root.yaml, использует блоки note/tabs/view/snippet/mermaid/openapi/drawio. Совместимость с визуальным редактором Gramax.
---

# Gramax Writer

Создание, редактирование и структурирование документации в формате Gramax (markdown + XML-расширения для визуального редактора).

## Core Principles

### 1. Сохраняй существующий формат

Если в репо уже есть контент — сохраняй структуру, нейминг, форматирование. Не переформатируй таблицы, не меняй синтаксис блоков.

### 2. Следуй syntax из `.doc-root.yaml`

Если указано `syntax: XML` — используй XML-теги (`<note>`, `<tabs>`, `<snippet/>`). Проверяй `.doc-root.yaml` перед редактированием.

### 3. Храни вложения рядом со страницей

Изображения, SVG, PDF, YAML, Mermaid-файлы — в той же папке, что и страница, которая их использует.

### 4. Не ломай макросы форматированием

Автоформатирование может сломать блоки Gramax. Сохраняй пустые строки вокруг `<note>`, `<tabs>`. Не трогай самозакрывающиеся теги и XML-форматы таблиц/изображений из визуального редактора.

## Workflow

### При первой операции

1. Найди `.doc-root.yaml` в корне каталога
2. Прочитай `syntax` (XML или Markdown) и `language`
3. Применяй соответствующее форматирование во всех последующих операциях

### При создании/редактировании

1. Определи целевую папку
2. Сформируй имя файла по правилам нейминга (см. ниже)
3. Создай frontmatter (`order`, `title`)
4. Добавь контент с блоками в правильном syntax

## Структура каталога

```
.
├── .doc-root.yaml             # конфигурация каталога — только в корне
├── simple-page.md             # листовая статья
├── parent-article/            # статья с дочерними — ДИРЕКТОРИЯ
│   ├── _index.md              # титульная страница этой статьи
│   ├── child-page.md
│   ├── image.png              # вложения рядом со страницей
│   └── nested-article/        # вложенная статья с дочерними
│       ├── _index.md
│       └── grandchild.md
└── another-article/
    └── _index.md
```

**Ключевые правила:**
- Папка = статья с дочерними. `_index.md` внутри = титульная страница этой статьи.
- Листовая статья = просто `article.md` (без папки).
- **Корень каталога (где `.doc-root.yaml`) НЕ должен содержать `_index.md`.**
- **Каждая подпапка с `.md`-файлами или вложенными папками ОБЯЗАНА содержать `_index.md`.** Без него Gramax не строит навигацию — папка не видна в дереве, статьи внутри недоступны.

Минимальный шаблон `_index.md` для подпапки-коллекции:

```markdown
---
order: <число>
title: <Название раздела>
---

<Одно-два предложения, что здесь хранится.>

| Файл | Описание |
|------|----------|
| [Название](файл.md) | Краткое описание |
```

**Правильно:**
```
catalog/
├── .doc-root.yaml
├── simple-page.md
└── main-section/
    ├── _index.md
    └── child-1.md
```

**Неправильно:**
```
catalog/
├── .doc-root.yaml
├── _index.md          ← ЗАПРЕЩЕНО в корне каталога
└── child-1.md
```

Операции со структурой (добавить/переместить/удалить/превратить страницу в раздел) → `references/structure.md`.

## Frontmatter

Каждый `.md` **обязан** начинаться с frontmatter. Формат отличается для статей и `_index.md`.

### Статья (любой `.md`, кроме `_index.md`)

```yaml
---
order: 1
title: "Заголовок статьи"
properties:
  - name: <Имя property из .doc-root.yaml>
    value: [<значение из enum>]
  - name: <следующий property>
    value: [<значение>]
---
```

- `order` — числовой порядок в навигации (целые или десятичные для вставки)
- `title` — заголовок на языке страницы; в кавычках если содержит `:` или начинается с цифры
- `properties` — **опционально**, список объектов `{name, value: [...]}`. **Object-нотация — единственно поддерживаемая для нового контента.** Имя должно совпадать с `name:` property в `.doc-root.yaml`. `value:` всегда массив (поддерживает мульти-select).

### `_index.md` (любая папка кроме корня каталога)

```yaml
---
order: 1
title: Название раздела
---
```

`_index.md` **не должен содержать** блок `properties:` — раздел не имеет собственных property, они определяются на статьях. Для фильтров по разделу — `<view>` блоки в теле (см. ниже).

### Антипаттерн: плоская нотация (LEGACY)

```yaml
properties:
  - Тип контента: ADR
  - Фаза: PoC
```

Встречается в старых каталогах. Gramax парсит, но рендерит непредсказуемо при несовпадении регистра ключей. **Не использовать в новом контенте.** При работе с legacy — мигрировать пакетно.

## `.doc-root.yaml` — кратко

Конфигурация каталога. Лежит в корне.

```yaml
title: My catalog
description: Описание каталога
language: ru
syntax: XML

properties:
  - name: Тип контента
    type: Enum
    style: green
    icon: file-text
    values: [Требование, ADR, Архитектура]

filterProperties: [Тип контента]
```

**Ключевое:**
- `properties` — список **объектов** с `name/type/style/icon/values`. То же `name:` используется в frontmatter статей.
- `style:` — цвет бейджа property (`green`, `blue`, `purple`, etc.). Палитра из 11 значений.
- `icon:` — любая иконка из Lucide (`https://lucide.dev/icons`).
- `filterProperties` — имена property, отображаемых в боковой панели фильтров.

Полный справочник (все ключи, палитра, антипаттерны) → `references/doc-root-schema.md`.

## Нейминг файлов и папок

Правила:
1. Транслитерация кириллицы в латиницу
2. Пробелы и спецсимволы → дефис `-`
3. Только lowercase
4. Удалить кавычки, скобки, точки (кроме расширения)
5. Множественные дефисы схлопнуть в один

Примеры:
| Заголовок | Имя файла |
|-----------|-----------|
| Быстрый старт | `bystryy-start.md` |
| Установка и настройка | `ustanovka-i-nastroyka.md` |
| Раздел «Документы» | `razdel-dokumenty/` |
| Что нового? | `chto-novogo.md` |

**Утилита:**
```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/slugify.py "Быстрый старт"           # → bystryy-start
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/slugify.py --filename "Что нового?"  # → chto-novogo.md
```

Полная таблица транслитерации → `references/blocks.md`.

## Ссылки

- Внутренние (без `.md`): `[Название](./другой-документ)` или `[Название](./../app/_index)`
- На раздел: `[Название](./features/_index)`
- На вложения (с расширением): `./diagram.png`, `./file.pdf`
- Кросс-каталожные: `[Название](project/Document/DOC-000XXX#якорь)`

**Cross-каталожные ссылки:** только inline code, не markdown link. Gramax не резолвит markdown-ссылки между разными `.doc-root.yaml`-каталогами:

❌ `[Документ](other-catalog/path/to/file.md)` — не работает
✅ `` `other-catalog/path/to/file.md` `` — работает (читается как путь)

## Изображения

Markdown:
```markdown
![](./screenshot.png){width=800 height=450}
```

XML (с кадрированием/аннотациями — НЕ редактировать `crop`/`objects` вручную):
```markdown
<image src="./image.png" crop="..." objects="..." width="800" height="450" float="center"/>
```

Вложения хранятся в той же папке, что и страница.

## Diagrams (Draw.io)

В Gramax диаграммы Draw.io хранятся как **SVG-файлы с встроенными drawio-данными**.

Синтаксис вставки:
```markdown
[drawio:./filename.svg:Описание:WIDTHpx:HEIGHTpx]
```

Примеры:
```markdown
[drawio:./architecture.svg:Общая схема процесса:971px:311px]
[drawio:./overview.svg::211px:101px]
```

**Конвертация `.drawio` → SVG** (обязательна при подготовке к загрузке):

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py input.drawio output.svg
```

Детали алгоритма, работа с кириллицей, декомпрессия для отладки → `references/drawio.md`.

## Краткий справочник блоков

| Блок | Синтаксис | Назначение |
|------|-----------|------------|
| Заметка | `<note type="tip">...</note>` | Callout (tip/info/warning/danger/...) |
| Табы | `<tabs><tab name="A">...</tab></tabs>` | Переключаемые вкладки |
| `<view>` | См. ниже | Динамический список с фильтрами по property |
| Сниппет | `<snippet id="name"/>` | Вставка из `.gramax/snippets/` |
| OpenAPI | `<openapi src="./api.yaml"/>` | Спецификация API |
| Mermaid | `<mermaid path="./diagram.mermaid" width="800px" height="450px"/>` | Диаграмма Mermaid |
| Видео | `<video path="URL"/>` | Встроенное видео |
| Иконка | `<icon code="lucide-name"/>` | Lucide-иконка |
| HTML | `<html>...</html>` | Сырой HTML |

### Дашборды через `<view>`

Используется в `_index.md` для списков статей с фильтрацией и группировкой:

```markdown
<view defs="Тип контента=ADR&Архитектура&none" groupby="Статус" display="List"/>
```

- `defs="<property>=<v1>&<v2>&none"` — фильтр по property; `none` означает «и статьи без значения». Несколько фильтров через `,`.
- `groupby="<property>"` — группировка результата.
- `display="List"` — представление.

**Когда использовать:** в корневом `_index.md` каталога (дашборд всех статей) или в крупных разделах (>20 статей). Малые разделы (<10 статей) — избыточно.

Подробности и примеры → `references/blocks.md`.

**UI-токены:** `[cmd:Label]`, `[kbd:Ctrl+S]`, `[alfa]`, `[beta]`

Полный справочник блоков (все типы note, markdown-admonitions `:::info`, таблицы в 3 синтаксисах, стилизация `<color>`/`<highlight>`, формулы, блочные комментарии) → `references/blocks.md`.

## Staging — pre-publish checklist

Перед подготовкой к загрузке в Gramax:

1. Удалить служебные файлы: `.DS_Store`, `Thumbs.db`, `CLAUDE.md`
2. **НЕ удалять** `.gramax/` (содержит сниппеты) и `.doc-root.yaml`
3. Конвертировать все `.drawio` → `.svg`
4. Проверить отсутствие `_index.md` в корне каталога
5. Проверить frontmatter у всех страниц

Автоматическая проверка:
```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py <path-to-catalog>
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py <path> --fix --yes   # удалить мусор
```

Полный чеклист → `references/staging.md`.

## Guardrails

- Не удаляй/переименовывай `.gramax/`
- При переименовании страниц — обнови все ссылки
- Валидируй парные теги (`<note>`, `<tabs>`, `<tab>`, `<html>`, `<comment>`, `<color>`, `<highlight>`)
- Сохраняй пустые строки внутри `<note>`, `<tabs>`
- Не редактируй числовые параметры `crop`/`objects` в XML-изображениях вручную

## Ресурсы

- `references/blocks.md` — полный справочник XML-блоков и токенов
- `references/drawio.md` — конвертация `.drawio` → SVG, алгоритм, отладка
- `references/structure.md` — операции со структурой (добавить/переместить/превратить страницу в раздел)
- `references/staging.md` — pre-publish checklist
- `references/doc-root-schema.md` — полный справочник `.doc-root.yaml`

## Production эталоны

Канонический референс структуры — реальный Gramax-каталог с production-данными: object-нотация frontmatter, `style:` + `icon:` на каждом property, `<view>`-дашборды в `_index.md`. При сомнениях о формате — опирайся на примеры в `references/doc-root-schema.md` и `references/structure.md`.
