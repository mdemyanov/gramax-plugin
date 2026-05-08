# Changelog

## 1.2.0 — 2026-05-08

Migration to dedicated marketplace repo `mdemyanov/gramax-plugin`. Plugin теперь поставляется как часть Claude Code marketplace, а не из монорепо `mdemyanov/ai-assistants`.

### Added
- `skills/diagrams/` — новый skill для drawio/mermaid в Gramax-каталогах. Бриджит существующий `scripts/drawio_convert.py` через `${CLAUDE_PLUGIN_ROOT}`. References: `drawio-workflow.md`, `mermaid-blocks.md`.
- `agents/review-agent.md` — агент-координатор для ревью комментариев. Workflow: inventory → triage → report → optional apply (gated на подтверждение). Использует comments-read/comments-write через Skill tool.

### Changed
- `homepage` / `repository` обновлены на `https://github.com/mdemyanov/gramax-plugin`.
- `keywords` дополнены `mermaid`, `review`.
- `description` отражает новый scope (4 skills + agent).

### Migration notes
- Плагин больше не доступен по адресу `ai-assistants/plugins/gramax`. Установка: `/plugin marketplace add mdemyanov/gramax-plugin`.
- Скрипты по тем же путях внутри плагина — пользовательские ссылки `${CLAUDE_PLUGIN_ROOT}/scripts/...` работают без изменений.
- Источник в `mdemyanov/ai-assistants` заменён на git submodule на этот репо (отдельный коммит в ai-assistants).

## 1.1.0 — 2026-05-06

Schema alignment с проверенным production-паттерном Gramax-каталога.

### Документация writer-skill
- Frontmatter явно разделён на статьи (object-нотация `properties: [- name/value: [...]]`) и `_index.md` (без `properties:`).
- Антипаттерн плоской нотации помечен как LEGACY.
- Подпапки обязаны содержать `_index.md` (без него Gramax не строит навигацию).
- Новый `references/doc-root-schema.md`: полный справочник конфигурации каталога — корневые ключи, property-определение, палитра `style:` (11 значений), Lucide-иконки, антипаттерны.
- В SKILL.md добавлен компактный раздел `.doc-root.yaml — кратко` со ссылкой на полный справочник.
- Расширен `<view>`: атрибуты `defs`/`groupby`/`display`, синтаксис фильтров, примеры.
- Cross-каталожные ссылки документированы как inline code (markdown link не резолвится Gramax-ом).
- Добавлена секция Production-паттерны со ссылкой на `references/`.

### Валидация
- `validate_structure.py` — пять новых проверок:
  - V1 (error): подпапки с `.md` обязаны иметь `_index.md`.
  - V2 (error): `_index.md` не должен содержать `properties:`.
  - V3 (warning): обнаружение устаревшей плоской нотации frontmatter.
  - V4 (error): `properties.name` должен быть объявлен в `.doc-root.yaml`.
  - V5 (error): значение Enum-property должно входить в `values:`.
- `code` в `.doc-root.yaml` сделано опциональным.
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
