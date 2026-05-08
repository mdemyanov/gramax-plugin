# Draw.io в Gramax — детальный гайд

В Gramax диаграммы Draw.io хранятся как **SVG-файлы с встроенными drawio-данными** (mxfile XML в атрибуте `content` корневого тега `<svg>`).

## Синтаксис вставки

```markdown
[drawio:./filename.svg:Описание:WIDTHpx:HEIGHTpx]
```

Параметры:
1. Относительный путь к SVG-файлу
2. Описание (может быть пустым: `::`)
3. Ширина (`NNNpx`)
4. Высота (`NNNpx`)

Примеры:
```markdown
[drawio:./my-diagram.svg:Общая схема процесса:971px:311px]
[drawio:./overview.svg::211px:101px]
```

## Устаревший формат

```markdown
[START Название.drawio](<./START Название.drawio>)
```

Встречается только в старых каталогах. Новые документы используют `[drawio:./file.svg:...]`.

## Конвертация `.drawio` → SVG (обязательно)

Если диаграммы в черновиках хранятся как `.drawio` (raw mxfile XML), перед загрузкой в Gramax их необходимо конвертировать в SVG с embedded drawio-данными.

### Формат SVG-обёртки

```xml
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     version="1.1" width="WIDTHpx" height="HEIGHTpx"
     viewBox="-0.5 -0.5 WIDTH HEIGHT"
     content="HTML-ESCAPED-MXFILE-CONTENT"><defs/><g/></svg>
```

### КРИТИЧНО: кодировка кириллицы

**НЕЛЬЗЯ** вставлять raw XML с кириллицей в атрибут `content` через простой `html.escape()` — Gramax/браузер прочитает content как Latin-1 и кириллица превратится в мусор.

Содержимое `<diagram>` **ОБЯЗАТЕЛЬНО** сжимать: **URL-encode → deflate → base64**. Это обеспечивает ASCII-only content без проблем с кодировкой.

### Алгоритм конвертации

1. Прочитать mxGraphModel XML (может содержать кириллицу)
2. Сжать: `urllib.parse.quote()` → `zlib.compress()[2:-4]` (raw deflate без zlib-header) → `base64.b64encode()`
3. Обернуть в `<mxfile><diagram>COMPRESSED</diagram></mxfile>`
4. HTML-экранировать обёртку mxfile (она ASCII-only после сжатия)
5. Вставить в атрибут `content` тега `<svg>`
6. Сохранить как `.svg` с UTF-8

### Готовый инструмент

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py input.drawio output.svg
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py input.drawio output.svg --width 1400 --height 700
```

Если `--width`/`--height` не заданы — извлекается из `<mxGraphModel pageWidth="..." pageHeight="...">`.

### Декомпрессия для отладки

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py --decompress ./diagram.svg
```

Вывод в stdout — исходный mxGraphModel XML.

## Правила размещения и именования

- SVG-файлы с диаграммами — **рядом со страницей** (не в подкаталоге `diagrams/`)
- Файлы `.drawio` в Gramax отображаются как вложения, а не как встроенные диаграммы → перед публикацией все `.drawio` должны быть сконвертированы и удалены
- При миграции из drafts — удалять папку `diagrams/` после конвертации

### Именование SVG-файлов

```
{slug-каталога}.svg              # основная схема
{slug-каталога}-2.svg            # вторая схема
{slug-каталога}-N.svg            # N-я схема
```

## Типичные проблемы

| Симптом | Причина | Решение |
|---------|---------|---------|
| Диаграмма отображается как вложение | Формат `.drawio` вместо SVG с embedded | Конвертировать через `drawio_convert.py` |
| Кириллица превращается в `Ð¿Ñ€Ð¸Ð²ÐµÑ‚` | Content вставлен как сырой XML | Использовать compress → base64 |
| `[drawio:./file.svg:…]` не рендерится | Нет размеров или неверный формат параметров | Проверить `WIDTHpx:HEIGHTpx` в конце |
| `viewBox` не совпадает с размерами | `viewBox="-0.5 -0.5 W H"` задан неверно | Использовать скрипт — автоматически |
