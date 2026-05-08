# Gramax Plugin

Claude Code plugin для работы с документацией в формате Gramax.

## Установка

```
/plugin marketplace add mdemyanov/ai-assistants
/plugin install gramax@ai-assistants
```

## Skills

- `/gramax:writer` — создание и редактирование Gramax-документов
- `/gramax:comments-read <path>` — показать комментарии документа
- `/gramax:comments-write <path>` — добавить/ответить/редактировать/удалить комментарий

## Scripts

Скрипты в `scripts/` доступны через `${CLAUDE_PLUGIN_ROOT}/scripts/...` или напрямую `uv run`:

- `drawio_convert.py` — конвертация `.drawio` → SVG с embedded drawio-данными
- `slugify.py` — транслит кириллицы в latin-slug для имён файлов
- `validate_structure.py` — pre-publish валидация каталога Gramax
- `parse_comments.py` — парсинг и отчёт по комментариям
- `gen_comment_id.py` — генерация уникального ID комментария
- `validate_comments.py` — валидация парности `<comment>` ↔ `.comments.yaml`

## Версия

1.0.0 — см. [CHANGELOG.md](./CHANGELOG.md)
