# Блоки Gramax — полный справочник

## Примечания (Notes / Admonitions)

### XML-формат (для `syntax: XML`)

```markdown
<note type="tip" title="Заголовок" collapsed="false">

Содержимое заметки.

</note>
```

| Параметр | Значения | Обязательный |
|----------|----------|--------------|
| `type` | `tip`, `info`, `hotfixes`, `quote`, `lab`, `note`, `warning`, `danger` | да |
| `title` | строка | нет |
| `collapsed` | `true`, `false` | нет |

**Правило:** пустые строки после `<note>` и перед `</note>` обязательны.

### Markdown-формат (для `syntax: Markdown`)

```markdown
:::info

Информационный блок.

:::

:::tip Заголовок

Подсказка с заголовком.

:::
```

## Табы (Tabs)

```markdown
<tabs>

<tab name="Python">

Код на Python.

</tab>

<tab name="JavaScript">

Код на JavaScript.

</tab>

</tabs>
```

Правила:
- Каждый `<tab>` обязан иметь `name`
- Пустые строки внутри обязательны
- Первая вкладка — активна по умолчанию

## Дашборды через `<view>`

Динамический список статей с фильтрами и группировкой. Используется в `_index.md`.

### Синтаксис

```markdown
<view defs="Тип контента=ADR&Архитектура&none" groupby="Статус" display="List"/>
```

### Атрибуты

| Атрибут | Назначение |
|---------|------------|
| `defs` | Фильтр: `"property1=val1&val2&none, property2=val3"`. Внутри property-фильтра `&` — OR; между разными property `,` — AND. `none` означает «и статьи без значения этого property». |
| `groupby` | Имя property для группировки результата (опц.) |
| `display` | Представление; на сегодня поддерживается `List` |

### Примеры

```markdown
### Статьи по статусу

<view defs="Тип=Документ&Статья&none" groupby="Статус" display="List"/>

### Статьи по категории

<view defs="Тип=Документ&Статья&none" groupby="Категория" display="List"/>
```

### Когда использовать

- ✅ Корневой `_index.md` каталога — дашборды всех статей
- ✅ `_index.md` крупного раздела (>20 статей) — для группировки
- ❌ Малые разделы (<10 статей) — избыточно, проще ручная таблица

### Связь со схемой

Имена property в `defs=` и `groupby=` должны совпадать с `name:` property в `.doc-root.yaml` (точно, с учётом регистра). См. `references/doc-root-schema.md`.

## Сниппеты (Snippets)

```markdown
<snippet id="common-warning"/>
```

Файлы сниппетов лежат в `.gramax/snippets/` — обычный markdown без frontmatter.

## Таблицы

### Markdown-таблицы (рекомендуемые)

```markdown
| Колонка | Тип | Обязательно |
|---------|-----|-------------|
| id | number | да |
| name | text | нет |
```

### Расширенные (с `colwidth`)

```markdown
{% table header="row" %}

---

*  {% colwidth=[383] %}

   **Заголовок**

*  {% colwidth=[532] %}

   **Описание**

---

*  Значение

*  Описание

{% /table %}
```

### XML-таблицы (визуальный редактор — НЕ переформатировать)

```markdown
<table header="row">
<tr>
<td>

Заголовок

</td>
<td>

Значение

</td>
</tr>
</table>
```

**Правило:** если `<table>` уже в файле — сохраняй формат как есть, включая пустые строки внутри `<td>`.

## OpenAPI

```markdown
<openapi src="./api.yaml" flag="true"/>
```

Параметры: `src` (путь к YAML/JSON), `flag` (`true`/`false` — показывать deprecated).

## Mermaid

```markdown
<mermaid path="./diagram.mermaid" width="800px" height="450px"/>
```

Файл `.mermaid` — стандартный синтаксис Mermaid.

## Видео

```markdown
<video path="https://youtube.com/watch?v=..."/>
```

## HTML

```markdown
<html>
<div class="custom">
  Произвольный HTML
</div>
</html>
```

## Иконки (Lucide)

```markdown
<icon code="lucide-check"/>
```

Список иконок: https://lucide.dev/icons

## Изображения

### Markdown

```markdown
![](./image.png){width=800 height=450}
```

### XML (с кадрированием/аннотациями)

```markdown
<image src="./image.png" crop="..." objects="..." width="800" height="450" float="center"/>
```

**Не редактируй** числовые параметры `crop` и `objects` вручную — генерируются редактором.

## Draw.io

```xml
<drawio path="./filename.svg" width="WIDTHpx" height="HEIGHTpx"/>
```

Файл `.svg` хранится рядом со статьёй, создаётся через `gramax:drawio`.

Устаревший формат (до v4.1.0): `[drawio:./filename.svg:Описание:WIDTHpx:HEIGHTpx]` — в новых документах не использовать.

Устаревший формат (в старых каталогах): `[START Name.drawio](<./START Name.drawio>)` — **не использовать для новых документов**. Конвертация и детали → `drawio.md`.

## Комментарии

### Inline

```markdown
Текст с <comment id="abc12">выделенным фрагментом</comment>.
```

### Block

```markdown
[comment:abc12]

Блок текста с комментарием.

[/comment]
```

ID — 5 символов `[a-zA-Z0-9]`. Для операций с комментариями → skill `gramax:comments-read` и `gramax:comments-write`.

## UI-токены

| Токен | Пример | Результат |
|-------|--------|-----------|
| `[cmd:Label]` | `[cmd:Сохранить]` | Кнопка/команда |
| `[cmd:Label:Icon]` | `[cmd:Добавить:plus]` | Кнопка с иконкой |
| `[kbd:Keys]` | `[kbd:Ctrl+S]` | Сочетание клавиш |
| `[alfa]` | `[alfa]` | Альфа-бейдж |
| `[beta]` | `[beta]` | Бета-бейдж |

## Стилизация текста

### XML

```markdown
<color color="#FF5733">Цветной текст</color>
<highlight color="yellow">Выделенный текст</highlight>
```

### Токен

```markdown
[color:#FF5733]Цветной текст[/color]
```

## Формулы

Inline:
```markdown
Формула $E = mc^2$ в тексте.
```

Block:
```markdown
$$
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
$$
```

Legacy (если встречается — сохраняй как есть):
```markdown
{%formula content="E = mc^2" /%}
```

## Спецсимволы

- Экранирование точек в нумерации: `5\.1. Заголовок`
- Перенос строки без разрыва абзаца: `Текст.\` (backslash в конце строки)

## Транслитерация (нейминг)

| Буква | Транслит | Буква | Транслит |
|-------|----------|-------|----------|
| а | a | р | r |
| б | b | с | s |
| в | v | т | t |
| г | g | у | u |
| д | d | ф | f |
| е | e | х | kh |
| ё | yo | ц | ts |
| ж | zh | ч | ch |
| з | z | ш | sh |
| и | i | щ | shch |
| й | y | ъ | (пропуск) |
| к | k | ы | y |
| л | l | ь | (пропуск) |
| м | m | э | e |
| н | n | ю | yu |
| о | o | я | ya |
| п | p | | |

## Валидация

### Парные теги (open + close)

- `<note>...</note>`
- `<tabs>...</tabs>`, `<tab>...</tab>`
- `<html>...</html>`
- `<comment>...</comment>`
- `[comment:id]...[/comment]`
- `<color>...</color>`, `<highlight>...</highlight>`
- `[color:...]...[/color]`

### Самозакрывающиеся теги

- `<view.../>`, `<snippet.../>`, `<openapi.../>`
- `<mermaid.../>`, `<video.../>`, `<icon.../>`
- `<image.../>`
