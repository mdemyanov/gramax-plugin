# Changelog

## 3.0.0 — 2026-05-11

Breaking change. Устранена путаница в роутинге диаграмм: добавлен явный skill `gramax:drawio` как заглушка-делегатор на внешний плагин, а vendored submodule `claude-mermaid` удалён — он создавал конфликт триггеров с `gramax:mermaid`.

### Added
- `skills/drawio/` — новый skill `gramax:drawio`. Точка входа для явных drawio-запросов («нарисуй drawio», «drawio-схема», «.drawio-файл»). Не генерирует диаграммы самостоятельно — делегирует на внешний `Agents365-ai/drawio-skill` и информирует о двухшаговом Gramax-workflow: drawio-skill создаёт `.drawio` + `.svg` → writer-skill помогает вставить тег `[drawio:...]`.
- `plugin.json` — skill `drawio` объявлен в секции `skills`.

### Removed
- `plugins/claude-mermaid/` — vendored MIT submodule удалён (конфликт триггеров с `gramax:mermaid`; директива пользователя 2026-05-11). MCP-инструменты `mermaid_preview` и `mermaid_save` из этого submodule более недоступны — это breaking change для пользователей, опиравшихся на MCP-preview.
- `.gitmodules` — запись `[submodule "plugins/claude-mermaid"]` удалена вместе с submodule.

### Changed
- `skills/mermaid/SKILL.md` — description уточнён по ADR-0009: убрано упоминание `Agents365-ai/mermaid-skill` как конфликтующего (разграничение теперь через `gramax:drawio`); добавлены явные generic-триггеры («визуализируй процесс/архитектуру» без движка); добавлен cross-ref `gramax:drawio`; добавлена секция «Fallback при ambiguous-request» — при запросе без явного engine-keyword задаётся уточняющий вопрос (mermaid inline vs drawio через внешний плагин).
- `.claude-plugin/marketplace.json` — удалена запись `claude-mermaid`; descriptions обновлены; version `3.0.0`.
- `plugins/gramax/.claude-plugin/plugin.json` — version `3.0.0`; description обновлён.
- Корневой `README.md` — раздел Skills обновлён: добавлен `gramax:drawio`, убраны упоминания `claude-mermaid`.
- `AGENTS.md`, `CLAUDE.md` — sunset-паттерн: удалены orphan-ссылки на `claude-mermaid` submodule.

### Migration notes

Для пользователей, переходящих с v2.x:

1. Обнови плагин: `/plugin update gramax` (или переустанови: `/plugin marketplace add mdemyanov/gramax-plugin && /plugin install gramax@gramax-marketplace`).
2. Проверь `~/.claude/settings.json` на наличие записи в `mcpServers` с ключом `mermaid` или `claude-mermaid`. Если запись есть — удали вручную: MCP-сервер более не входит в marketplace. Если Claude Code сообщает «MCP server not found» для mermaid — это следствие удаления submodule; `gramax:mermaid` работает без MCP.
3. Для drawio-диаграмм установи внешний плагин:
   ```
   /plugin marketplace add Agents365-ai/365-skills
   /plugin install drawio
   ```
   А также **draw.io desktop** (macOS: `brew install --cask drawio`; Linux: `.deb`/`.rpm` с [releases](https://github.com/jgraph/drawio-desktop/releases), не snap) и **Python 3** (нужен внешнему плагину).
4. MCP-preview (`mermaid_preview`, `mermaid_save`) из `claude-mermaid` более не поддерживается. Для inline mermaid — используй `gramax:mermaid` как прежде, он работает без изменений.
5. При неявном запросе («нарисуй диаграмму» без указания движка) `gramax:mermaid` задаст уточняющий вопрос. Для детерминированного выбора — указывай движок явно в запросе. Подробнее — в `plugins/gramax/skills/mermaid/SKILL.md` (секция «Fallback при ambiguous-request»).

### ADR
- ADR-0009 (новый) — обоснование удаления `claude-mermaid`, добавления `gramax:drawio`, keyword-стратегия description, процедура `git submodule deinit`. Документ: `docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md`.
- ADR-0008 остаётся Active — ADR-0009 дополняет его, не отменяет.

### Backward compatibility

- Имя skill'а `gramax:mermaid` не изменилось — явные запросы с «mermaid» в тексте работают без изменений.
- Inline-генерация mermaid DSL работает идентично v2.0.0.
- Skills `writer`, `comments-read`, `comments-write` и agent `review-agent` не затронуты.
- **Known limitation:** при неявном запросе («нарисуй диаграмму» без движка) Claude может активировать `gramax:drawio` вместо `gramax:mermaid`. Полный детерминизм — только при явном engine-keyword в запросе (см. ADR-0009, Решение 6).

## 2.0.0 — 2026-05-11

Breaking change. Внутренние diagram-skills удалены; drawio делегирован внешнему плагину.

### Removed
- `skills/diagram-on-demand/` — удалён. Замена: внешний плагин `Agents365-ai/drawio-skill` для drawio; встроенный `mermaid` для mermaid.
- `skills/diagrams/` — удалён. Гайд по drawio/mermaid переезжает в `skills/writer/references/drawio.md` (новый workflow) и `skills/mermaid/SKILL.md`.
- Четыре bash-скрипта из `scripts/` (обслуживали только удалённые skills) — удалены. Полный список в теге `v1.4.0`.
- Python-скрипт конвертации drawio→SVG из `scripts/` — удалён. При необходимости: возьми версию из тега `v1.4.0`.

### Changed
- `skills/writer/SKILL.md` и `skills/writer/references/drawio.md` — переработаны: drawio-генерация делегирована внешнему плагину; описан двухшаговый workflow и Gramax-теги (`[drawio:...]` для Markdown, `<Image>` для XML).
- `skills/writer/references/staging.md` — обновлён чек-лист: шаг конвертации drawio переработан (без внутреннего python-скрипта).
- `skills/mermaid/SKILL.md` description уточнено: только Mermaid DSL; drawio → внешний плагин.
- `.claude-plugin/marketplace.json` и `plugins/gramax/.claude-plugin/plugin.json` — версия `2.0.0`, descriptions обновлены без `diagrams`/`diagram-on-demand`.

### Migration notes

При переходе с `diagram-on-demand`, `diagrams` или внутренних drawio-скриптов плагина:

1. Обнови плагин: `/plugin update gramax`.
2. Установи внешний drawio-плагин:
   ```
   /plugin marketplace add Agents365-ai/365-skills
   /plugin install drawio
   ```
3. Поставь **draw.io desktop** (macOS: `brew install --cask drawio`; Windows/Linux: [github.com/jgraph/drawio-desktop/releases](https://github.com/jgraph/drawio-desktop/releases) — не используй snap на Linux).
4. Поставь **Python 3** (требуется `repair_png.py` внутри внешнего плагина).
5. Существующие `.drawio`/`.svg` файлы в Gramax-каталогах продолжают рендериться — меняется только workflow создания новых.
6. Внешний плагин `drawio-skill` не вставляет ссылку в md автоматически — после генерации вставь тег вручную (writer-skill подскажет формат): `[drawio:./file.svg:alt:WxHpx]` для Markdown-syntax, `<Image src="./file.svg" />` для XML-syntax.

**Не устанавливай** `Agents365-ai/mermaid-skill` параллельно с `gramax:mermaid` — конфликт триггеров.

### ADR
- ADR-0008 (новый) — обоснование breaking change.
- ADR-0001, 0004, 0005, 0007 → статус `Superseded by ADR-0008`.
- ADR-0002, 0003 → статус `Historical (Informational)`.
- ADR-0006 остаётся Active (semver-policy применён здесь).

## 1.4.0 — 2026-05-08

### Added
- `skills/mermaid/` — новый skill для генерации mermaid-диаграмм по текстовому описанию без внешних зависимостей. Адаптирован из upstream [axtonliu/axton-obsidian-visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills) (MIT). Учитывает синтаксис Gramax-каталога (XML или Markdown через `.doc-root.yaml`), 8 поддерживаемых типов, защита от типовых ошибок парсера (list-syntax conflict, subgraph naming, node references). Не использует MCP-серверы — генерация и вставка DSL inline.
- `skills/mermaid/references/syntax-rules.md` — расширенный справочник синтаксиса, troubleshooting и advanced паттернов.
- `skills/mermaid/LICENSE.upstream.md` — MIT-attribution upstream-источника со списком изменений.

### Сохранено без изменений
- Skill `diagram-on-demand` и `diagrams` — не затронуты; `mermaid` дополняет их inline-вариантом без зависимостей.

## 1.3.0 — 2026-05-08

### Added
- `skills/diagram-on-demand/` — новый skill для явной генерации mermaid/drawio по описанию с сохранением в Gramax-каталог. Принимает параметры `engine`, `description`, `target_page`; определяет синтаксис каталога через `.doc-root.yaml` (XML или Markdown) и вставляет ссылку автоматически.
- Четыре вспомогательных bash-скрипта в `scripts/` для поддержки diagram-on-demand: поиск `.doc-root.yaml`, валидация типа диаграммы, сохранение mxfile/SVG, вставка ссылки в md (удалены в 2.0.0).
- Опциональная поддержка `lgazo/drawio-mcp-server` для SVG-конвертации drawio — подключается через `mcpServers` в локальном `settings.json`, не обязателен.

### Сохранено без изменений
- Skill `diagrams` — не затронут; `diagram-on-demand` является дополнением, а не заменой.

## 1.2.0 — 2026-05-08

Migration to dedicated marketplace repo `mdemyanov/gramax-plugin`. Plugin теперь поставляется как часть Claude Code marketplace, а не из монорепо `mdemyanov/ai-assistants`.

### Added
- `skills/diagrams/` — новый skill для drawio/mermaid в Gramax-каталогах. Использует внутренний python-скрипт конвертации drawio→SVG (удалён в 2.0.0). References: `drawio-workflow.md`, `mermaid-blocks.md`.
- `agents/review-agent.md` — агент-координатор для ревью комментариев. Workflow: inventory → triage → report → optional apply (gated на подтверждение). Использует comments-read/comments-write через Skill tool.

### Changed
- `homepage` / `repository` обновлены на `https://github.com/mdemyanov/gramax-plugin`.
- `keywords` дополнены `mermaid`, `review`.
- `description` отражает новый scope (4 skills + agent).

### Migration notes
- Плагин больше не доступен по адресу `ai-assistants/plugins/gramax`. Установка: `/plugin marketplace add mdemyanov/gramax-plugin`.
- Скрипты по тем же путям внутри плагина — пользовательские ссылки `${CLAUDE_PLUGIN_ROOT}/scripts/...` работают без изменений.
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
- `scripts/drawio/` — конвертация `.drawio` → SVG с правильной обработкой кириллицы (удалён в 2.0.0)
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
