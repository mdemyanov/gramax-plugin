# Draw.io в Gramax — гайд

Drawio-диаграммы делегированы внешнему плагину **`Agents365-ai/drawio-skill`**. Этот файл описывает prerequisites, двухшаговый workflow и Gramax-теги для вставки результата.

## Prerequisites

### draw.io desktop

Внешний плагин вызывает draw.io desktop для конвертации. Установка:

- **macOS:** `brew install --cask drawio`
- **Windows:** скачай installer с [github.com/jgraph/drawio-desktop/releases](https://github.com/jgraph/drawio-desktop/releases)
- **Linux:** скачай `.deb` или `.rpm` с того же адреса. **Не используй snap** — AppArmor блокирует запись файлов из snap-окружения.
- **Linux headless:** нужен Xvfb: `sudo apt-get install xvfb`, запуск: `xvfb-run drawio --export ...`

### Python 3

Внешний плагин использует `repair_png.py` для постобработки. Python 3 должен быть установлен и доступен в PATH.

### Установка внешнего плагина

```
/plugin marketplace add Agents365-ai/365-skills
/plugin install drawio
```

## Двухшаговый workflow

Внешний плагин `drawio-skill` не знает структуры `.doc-root.yaml` и не вставляет ссылку в md автоматически. Поэтому процесс двухшаговый:

**Шаг 1 — Вызвать drawio-skill и получить файл.**

Опиши диаграмму — Claude выберет drawio-skill по триггеру. Skill создаст `.drawio` (и/или `.svg`) рядом с указанным путём.

**Шаг 2 — Вставить тег в md вручную.**

После получения файла вставь тег в нужное место страницы (см. раздел «Gramax-теги» ниже). Writer-skill подскажет правильный формат, если указать путь к файлу и синтаксис каталога.

## Gramax-теги для drawio

Тег зависит от поля `syntax:` в ближайшем `.doc-root.yaml` (обход вверх от target_page).

### Markdown syntax (default или `syntax: Markdown`)

```markdown
[drawio:./diagram.svg:Подпись:971px:311px]
```

Параметры:
1. Относительный путь к SVG-файлу
2. Подпись (может быть пустой: `::`)
3. Ширина (`NNNpx`)
4. Высота (`NNNpx`)

Примеры:
```markdown
[drawio:./architecture.svg:Общая схема процесса:971px:311px]
[drawio:./overview.svg::211px:101px]
```

### XML syntax (`.doc-root.yaml` → `syntax: XML`)

```xml
<Image src="./diagram.svg" />
```

## Правила размещения

- SVG-файлы — **рядом со страницей** (не в подкаталоге `diagrams/`)
- Сырые `.drawio` без `.svg` не публиковать в Gramax
- При миграции из черновиков: убедись что каждый `.drawio` имеет парный `.svg`

## Troubleshooting

| Симптом | Причина | Решение |
|---------|---------|---------|
| Диаграмма отображается как вложение | Файл `.drawio` вместо SVG | Конвертировать через drawio desktop или внешний плагин `drawio-skill` |
| Linux: конвертация падает с ошибкой display | Нет Xvfb | `xvfb-run drawio --export ...` |
| Linux snap: ошибка записи файла | AppArmor блокирует snap | Установить `.deb`/`.rpm` вместо snap |
| Windows: Python не найден | Python 3 не в PATH | Добавить Python в PATH или использовать `py -3` |
| `[drawio:./file.svg:…]` не рендерится | Нет размеров или неверный формат | Проверить `WIDTHpx:HEIGHTpx` в конце тега |
