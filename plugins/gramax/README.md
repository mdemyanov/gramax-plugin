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
- `/gramax:diagrams` — правила создания и встраивания .drawio / mermaid диаграмм
- `/gramax:diagram-on-demand` — явная генерация mermaid/drawio по описанию с сохранением в Gramax-каталог

### Skill `diagram-on-demand`

Генерирует диаграмму по словесному описанию и вставляет ссылку в нужную md-страницу.

Триггеры: «нарисуй mermaid», «сделай drawio-схему», «добавь диаграмму», «создай mermaid-диаграмму», «нарисуй flowchart».

Обязательные параметры (skill запросит, если не указаны):
- `engine` — `mermaid` или `drawio`
- `description` — словесное описание диаграммы
- `target_page` — путь к `.md`-файлу, рядом с которым сохраняется результат

Пример запроса:

```
Нарисуй mermaid flowchart процесса авторизации: логин → проверка токена → dashboard или ошибка.
Сохрани рядом с docs/auth/login-flow.md.
```

Что произойдёт:

1. Skill найдёт `.doc-root.yaml` вверх по дереву (`find_doc_root.sh`) и определит синтаксис каталога (XML или Markdown).
2. Сгенерирует mermaid DSL или drawio mxfile XML.
3. Сохранит файл(ы) рядом с `target_page` через `save_diagram.sh`.
4. Вставит ссылку в `target_page` через `insert_diagram_ref.sh` в правильном синтаксисе.
5. Выведет `Created: <path>` и вставленный фрагмент.

Поддерживаемые типы mermaid: `flowchart`, `sequenceDiagram`, `gantt`, `classDiagram`, `stateDiagram-v2`, `erDiagram`, `pie`, `mindmap`.

При запросе неподдерживаемого типа skill выведет `[WARN]` и не создаст файлы.

#### Drawio MCP (опционально)

По умолчанию drawio-путь использует локальный `drawio_convert.py` для получения SVG из `.drawio`. Для SVG-конвертации через MCP-сервер подключи `@lgazo/drawio-mcp-server`:

```json
// ~/.claude/settings.json (или .claude/settings.local.json проекта)
{
  "mcpServers": {
    "drawio": {
      "command": "npx",
      "args": ["-y", "@lgazo/drawio-mcp-server@2.1.0"]
    }
  }
}
```

После подключения MCP-сервер используется автоматически, если доступен. Если недоступен — skill выводит `[ERROR]` с командой ручной конвертации и завершается с exit code 1.

## Agents

- `review-agent` — координирует ревью комментариев в каталоге (запуск через Task tool)

## Scripts

Скрипты в `scripts/` доступны через `${CLAUDE_PLUGIN_ROOT}/scripts/...`:

- `drawio_convert.py` — конвертация `.drawio` → SVG с embedded drawio-данными
- `slugify.py` — транслит кириллицы в latin-slug для имён файлов
- `validate_structure.py` — pre-publish валидация каталога Gramax
- `parse_comments.py` — парсинг и отчёт по комментариям
- `gen_comment_id.py` — генерация уникального ID комментария
- `validate_comments.py` — валидация парности `<comment>` ↔ `.comments.yaml`
- `find_doc_root.sh` — поиск `.doc-root.yaml` вверх по дереву от указанного файла
- `validate_diagram_type.sh` — проверка типа mermaid на поддерживаемость
- `save_diagram.sh` — сохранение drawio XML + конвертация в SVG
- `insert_diagram_ref.sh` — вставка ссылки на диаграмму в md с учётом синтаксиса каталога

## Версия

1.3.0 — см. [CHANGELOG.md](./CHANGELOG.md)
