# Changelog

## 1.1.0 — 2026-05-06

Schema alignment с production-эталоном `<gramax-catalog>/`. Закрывает 8 из 9 находок из `example-project/docs/gramax-skills-update.md` (см. ADR-028 проекта example-project).

### Документация writer-skill
- Frontmatter явно разделён на статьи (object-нотация `properties: [- name/value: [...]]`) и `_index.md` (без `properties:`).
- Антипаттерн плоской нотации помечен как LEGACY.
- Подпапки обязаны содержать `_index.md` (без него Gramax не строит навигацию).
- Новый `references/doc-root-schema.md`: полный справочник конфигурации каталога — корневые ключи, property-определение, палитра `style:` (11 значений), Lucide-иконки, антипаттерны.
- В SKILL.md добавлен компактный раздел `.doc-root.yaml — кратко` со ссылкой на полный справочник.
- Расширен `<view>`: атрибуты `defs`/`groupby`/`display`, синтаксис фильтров, примеры из эталона.
- Cross-каталожные ссылки документированы как inline code (markdown link не резолвится Gramax-ом).
- Новая секция Production эталоны указывает на `<gramax-catalog>/` как канонический референс.

### Валидация
- `validate_structure.py` — пять новых проверок:
  - V1 (error): подпапки с `.md` обязаны иметь `_index.md`.
  - V2 (error): `_index.md` не должен содержать `properties:`.
  - V3 (warning): обнаружение устаревшей плоской нотации frontmatter.
  - V4 (error): `properties.name` должен быть объявлен в `.doc-root.yaml`.
  - V5 (error): значение Enum-property должно входить в `values:`.
- `code` в `.doc-root.yaml` сделано опциональным (соответствует production-эталону `example-catalog`).
- Экспериментальный `type: select` с `values: [{name: X}]` — V4/V5 пропускаются с однократным warning.

### Тесты
- `scripts/tests/test_validate_structure.py` — smoke-тесты на фикстурах good/bad.
- Запуск: `python3 plugins/gramax/scripts/tests/test_validate_structure.py`.

### Не вошло (отложено)
- `--migrate-frontmatter` CLI — отдельный спек, когда возникнет конкретный кандидат миграции.

## 1.0.0 — 2026-04-19

Первая версия плагина. Замещает монолитный `skills/gramax/` (архивирован в `archive/gramax-v1.0.0/`).

### Skills
- `writer` — расширенный writer с поддержкой drawio, staging, структурных правил
- `comments-read` — операционный workflow чтения комментариев
- `comments-write` — операционный workflow add/reply/edit/delete

### Scripts
- `drawio_convert.py` — конвертация `.drawio` → SVG с правильной обработкой кириллицы
- `slugify.py` — транслит кириллицы → latin-slug
- `validate_structure.py` — валидация каталога Gramax (с `--fix --yes`)
- `parse_comments.py` — парсинг комментариев (JSON/report, фильтры)
- `gen_comment_id.py` — генерация 5-символьных ID с проверкой уникальности
- `validate_comments.py` — парность md↔yaml, обязательные поля

### Контент (новое по сравнению с `skills/gramax/`)
- Запрет `_index.md` в корне каталога
- Markdown-admonitions (`:::info`, `:::tip`)
- Block-комментарии `[comment:id]...[/comment]`
- Расширенные таблицы `{% table %}`
- Стилизация (`<color>`, `<highlight>`)
- Формулы (inline/block/legacy)
- Типы note: `warning`, `danger`, `note`
- Staging-checklist (удаление `.DS_Store`, `CLAUDE.md`, сохранение `.gramax/`)
