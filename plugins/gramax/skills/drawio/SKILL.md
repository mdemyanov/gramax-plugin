---
name: drawio
description: "Только для drawio-диаграмм — НЕ для mermaid. Точка входа для создания drawio-схем в Gramax. Используй когда: «нарисуй drawio», «drawio-схема», «drawio-диаграмма», «схема drawio», «сделай .drawio-файл», «нарисуй диаграмму drawio». Не для: flowchart/sequence/gantt без упоминания drawio — используй gramax:mermaid. Для inline-диаграмм без drawio → gramax:mermaid. Делегирует генерацию на внешний плагин Agents365-ai/drawio-skill; результат вставляется тегом <drawio path=\"...\"/> в md."
---

# Drawio для Gramax

Заглушка-делегатор: этот skill не генерирует drawio-схемы самостоятельно. Он направляет к внешнему плагину `Agents365-ai/drawio-skill` и описывает двухшаговый Gramax-workflow.

## When to use

Активируй этот skill при явных drawio-запросах:
- «нарисуй drawio-схему», «сделай drawio-диаграмму»
- «drawio-схема архитектуры», «схема drawio», «.drawio-файл»
- «нарисуй диаграмму drawio», «создай drawio»

**НЕ для:** mermaid DSL, flowchart/sequence/gantt без упоминания drawio. Для mermaid-запросов → `gramax:mermaid`.

## Prerequisites

Для работы drawio необходим внешний плагин. Установи его один раз:

```
/plugin marketplace add Agents365-ai/365-skills
/plugin install drawio
```

Также потребуется:
- **draw.io desktop** — macOS: `brew install --cask drawio`; Windows/Linux: [github.com/jgraph/drawio-desktop/releases](https://github.com/jgraph/drawio-desktop/releases) (не snap на Linux)
- **Python 3** — требуется внутри drawio-skill для обработки файлов

## Workflow (двухшаговый)

Drawio-skill не знает о Gramax и не вставляет тег автоматически. После генерации нужен ручной шаг вставки.

**Шаг 1 — создай файл через drawio-skill:**
```
/drawio <описание диаграммы>
```
Drawio-skill создаст `.drawio` + `.svg` в рабочей директории.

**Шаг 2 — вставь тег в md-страницу:**

```xml
<drawio path="./diagram.svg" width="800px" height="600px"/>
```

## Gramax-тег

```xml
<drawio path="./file.svg" width="800px" height="600px"/>
```

Параметры: `path` — относительный путь к SVG; `width`, `height` — размеры.

**Примечание:** `drawio-skill` создаёт файл в CWD, тег не вставляет. Вставка — всегда Шаг 2 вручную (или через `gramax:writer`).

## Fallback при ambiguous-request

Если пользователь не указал движок явно («нарисуй диаграмму», «визуализируй процесс»), задай уточняющий вопрос:

> Какой движок использовать для диаграммы?
>
> 1. **mermaid** — файл `.mermaid` рядом со статьёй, тег-ссылка в md; рендер Gramax-фронтендом. Подходит для flowchart, sequence, gantt, ER, state, class, pie, mindmap.
> 2. **drawio** — через внешний плагин `Agents365-ai/drawio-skill`; создаёт `.svg`-файл рядом со статьёй, тег `<drawio path="..."/>` в md. Подходит для сложных схем, BPMN, кастомных стилей.
>
> По умолчанию — **mermaid**, если не укажешь.

После ответа пользователя:
- mermaid → делегируй в `gramax:mermaid`
- drawio → выполни Шаг 1 + Шаг 2 выше

## Не для

- **Mermaid DSL** — используй `gramax:mermaid`
- **Preview диаграмм в браузере** — mermaid-preview через MCP более не поддерживается
- **Inline-генерация без файла** — drawio всегда создаёт `.svg`-файл
