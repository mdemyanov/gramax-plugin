# Pre-publish checklist — подготовка каталога к загрузке в Gramax

Перед загрузкой каталога в Gramax (или переносом в staging-директорию) проверь все пункты ниже.

## 1. Удалить служебные файлы

| Файл/папка | Что это | Удалять? |
|------------|---------|----------|
| `.DS_Store` | Файл macOS | **Да** |
| `Thumbs.db` | Файл Windows | **Да** |
| `CLAUDE.md` | Инструкции для Claude Code | **Да** |
| `.git/` | Git-репозиторий | **Да** (если в staging) |
| `.gramax/` | Сниппеты, служебные данные редактора | **Нет — сохранить** |
| `.doc-root.yaml` | Манифест каталога | **Нет — обязателен** |
| `*.drawio` | Сырые mxfile | **Да** — после конвертации в SVG |

Быстрая проверка и автоудаление:
```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py <path>            # список нарушений
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py <path> --fix --yes # автоудалить мусор
```

## 2. Конвертировать `.drawio` → `.svg`

Все диаграммы должны быть в формате SVG с embedded drawio-данными:

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py file.drawio file.svg
```

Если был подкаталог `diagrams/` с сырыми `.drawio` — удалить после конвертации.

Детали → `drawio.md`.

## 3. Проверить отсутствие `_index.md` в корне каталога

На уровне `.doc-root.yaml` не должно быть `_index.md`. Если есть — переместить содержимое в отдельную папку `section/_index.md` или удалить.

## 4. Проверить frontmatter всех страниц

Каждый `.md` файл должен начинаться с:

```yaml
---
order: 1
title: Заголовок
---
```

Без frontmatter страница не будет корректно отображаться в навигации.

## 5. Проверить парность тегов

Парные теги (должны иметь закрывающую пару):
- `<note>...</note>`
- `<tabs>...</tabs>`, `<tab>...</tab>`
- `<html>...</html>`
- `<comment>...</comment>`
- `[comment:id]...[/comment]`
- `<color>...</color>`, `<highlight>...</highlight>`

Самозакрывающиеся теги (не требуют закрытия):
- `<view/>`, `<snippet/>`, `<openapi/>`
- `<mermaid/>`, `<video/>`, `<icon/>`, `<image/>`

## 6. Проверить комментарии

Для каждого `<comment id="X">` или `[comment:X]` должна быть запись в соответствующем `.comments.yaml`:

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_comments.py <path>
```

## 7. Итоговая проверка

```bash
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py <path> --strict
uv run ${CLAUDE_PLUGIN_ROOT}/scripts/validate_comments.py <path> --strict
```

Если оба завершились с exit 0 — каталог готов к загрузке.

## Типичные ошибки

| Симптом при загрузке | Причина |
|----------------------|---------|
| Страница не видна в дереве | Нет frontmatter или некорректный |
| Блок `<note>` рендерится как текст | Незакрытый тег или нет пустых строк |
| Диаграмма показана как вложение | `.drawio` вместо SVG |
| Ошибка структуры | `_index.md` в корне каталога |
| Комментарии пропали | `.comments.yaml` не перенесён со страницей |
