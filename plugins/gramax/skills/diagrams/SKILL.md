---
name: diagrams
description: Создание и встраивание диаграмм (drawio, mermaid) в Gramax-каталоги. Используй когда пользователь добавляет диаграмму в Gramax-страницу, конвертирует .drawio в SVG, вставляет mermaid-блок, или редактирует существующую диаграмму. Не для общего рендеринга диаграмм вне Gramax.
---

# Gramax Diagrams

Skill для добавления диаграмм в Gramax-каталоги. Дополняет writer: writer описывает структуру и блоки страниц, diagrams — правила работы с .drawio и mermaid внутри этих страниц.

## When to use

- Пользователь хочет добавить .drawio-схему в Gramax-страницу.
- Нужно конвертировать существующий .drawio в SVG для отображения в Gramax.
- Пользователь добавляет mermaid-диаграмму (flowchart, sequence, gantt и т.п.) в md.
- Редактирование/обновление существующей диаграммы.

**Не для:** интерактивного preview диаграмм (см. отдельный плагин `claude-mermaid`), генерации диаграмм из произвольного кода (используй mcp drawio/mermaid сервер вне scope).

## Core principles

### 1. Вложения рядом со страницей

Любой `.drawio` или `.svg` файл диаграммы кладётся в ту же папку, что и md-страница, которая на него ссылается. Никаких общих `assets/` каталогов.

```
my-section/
├── overview.md            # ссылается на architecture.svg
├── architecture.drawio    # исходник
└── architecture.svg       # сконвертированный с embedded drawio-данными
```

### 2. SVG с embedded drawio-данными

Всегда конвертируем .drawio в SVG через `drawio_convert.py` — он сохраняет исходник внутри SVG (атрибут `content`), что позволяет позже редактировать диаграмму обратно в drawio.

### 3. Mermaid — fenced или XML, по syntax из .doc-root.yaml

Если в `.doc-root.yaml` указан `syntax: XML`, используй `<mermaid>...</mermaid>`. Иначе fenced ```mermaid```. Не смешивай в одном каталоге.

## Drawio workflow

См. подробный workflow в `references/drawio-workflow.md`.

Краткая последовательность:
1. Создать/получить `.drawio` файл рядом со страницей.
2. Конвертировать в SVG: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py path/to/diagram.drawio`
3. В md-странице вставить:
   ```xml
   <Image src="diagram.svg" />
   ```
   (или markdown-вариант `![alt](diagram.svg)` если syntax: Markdown)

## Mermaid blocks

См. подробности в `references/mermaid-blocks.md`.

Краткое правило:
- Markdown syntax:
  ```markdown
  ```mermaid
  flowchart TD
    A --> B
  ```
  ```
- XML syntax:
  ```xml
  <mermaid>
  flowchart TD
    A --> B
  </mermaid>
  ```

## Используемые скрипты

- `${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py` — `.drawio → .svg` с embedded данными. Корректно обрабатывает кириллицу.

## Проверка перед коммитом

- Все `.drawio` имеют рядом `.svg` (или ссылка идёт на `.drawio` напрямую — если фронт умеет).
- В md нет ссылок на несуществующие файлы.
- Mermaid-блоки используют тот же синтаксис, что и остальной каталог (XML или Markdown).
