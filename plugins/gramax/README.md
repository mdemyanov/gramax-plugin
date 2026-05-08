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

## Версия

1.2.0 — см. [CHANGELOG.md](./CHANGELOG.md)
