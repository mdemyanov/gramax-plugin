# Drawio Workflow

Подробный workflow для добавления .drawio-диаграмм в Gramax-каталог.

## 1. Создание .drawio

Drawio-файл создаётся вручную в редакторе [diagrams.net](https://app.diagrams.net/) или через интеграцию IDE (расширение `hediet.vscode-drawio`).

Сохраняй с расширением `.drawio` (не `.drawio.svg`, не `.drawio.png`) — `drawio_convert.py` ожидает чистый XML.

## 2. Размещение

Файл `.drawio` кладётся рядом с md-страницей, которая на него ссылается:

```
products/auth/
├── login-flow.md
├── login-flow.drawio
└── login-flow.svg     # генерируется на шаге 3
```

Имена должны совпадать с именем страницы (или быть осмысленным slug). Кириллицу в имени файла не используй — применяй `slugify.py` если нужно (`python3 ${CLAUDE_PLUGIN_ROOT}/scripts/slugify.py "Поток входа"` → `potok-vhoda`).

## 3. Конвертация в SVG

Запусти:
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py products/auth/login-flow.drawio
```

Результат: `products/auth/login-flow.svg` — SVG с embedded drawio-данными внутри (атрибут `content` корневого `<svg>`).

Проверка embedded:
```bash
grep -c 'content=' products/auth/login-flow.svg
```
Ожидаемо: 1.

## 4. Вставка в md

В syntax XML:
```xml
<Image src="login-flow.svg" alt="Поток входа пользователя" />
```

В syntax Markdown:
```markdown
![Поток входа пользователя](login-flow.svg)
```

## 5. Обновление диаграммы

Открой `.svg` в drawio (он восстановит структуру из embedded `content`), внеси правки, сохрани в исходный `.drawio`, повтори шаг 3.

**Не редактируй SVG напрямую** — потеряешь embedded XML.

## Troubleshooting

- **Иконки/шрифты не отображаются**: убедись, что drawio-файл сохранён без external-зависимостей (`Edit > Diagram options > Math typesetting = OFF`).
- **Кириллица сломалась**: пересохрани `.drawio` в UTF-8 (drawio.app делает это по умолчанию).
- **drawio_convert.py упал**: проверь Python версию (нужен 3.8+) и что файл — валидный XML.
