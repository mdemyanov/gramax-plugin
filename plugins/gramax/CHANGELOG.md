# Changelog

## 4.4.0 — 2026-08-12

Render-killer-linter: новый контент-линтер `scripts/validate_render.py` — порт
`validate-gramax.py` плагина `gramax-skills` (MIT, автор Всеволод Шадрин; атрибуция и список
изменений — `scripts/LICENSE.upstream.md`). Ловит конструкции, роняющие рендерер GES (HTTP 500)
или ломающие вёрстку, на уровне ERROR с номером строки и подсказкой. Демаркация с W034
(ADR-0019): `<th>` владеет рендер-линтер, структурный валидатор не дублирует («одна находка
на дефект»). Маскирование кода (fenced + inline) вынесено в общий `lib/md_code_mask.py`.
Semver — Minor (ADR-0006, ADR-0019).

Healthcheck-port: в `validate_structure.py` портированы 4 категории ресурсных проверок из
движка Gramax Healthcheck + таксономия `--groups`. Два новых lib-модуля (`md_link_parser.py`,
`link_resolver.py`) с 14 unit-тестами. 7 acceptance-тестов (ac-014–ac-020) и 7 тестовых
фикстур. Все новые проверки — WARNING, не ломают exit code без `--strict`. Semver — Minor
(ADR-0006): аддитивная фича, существующие коды ошибок и формат вывода без `--groups` сохранены.

### Added

- **`scripts/validate_render.py`** (new) — линтер рендер-киллеров (FR-104…FR-112): `<th>`,
  инлайновый `<note>…</note>`, `<note>` в ячейке `<td>`/`<th>`, `<note>` в `<note>`,
  несколько `![](` в строке, несбалансированные парные теги
  (`note/table/tr/td/th/tabs/tab/color/highlight`) — ERROR; H1 в теле, frontmatter
  `title:` без кавычек — WARN
- **`gramax-render-rules.json`** (new) — контракт киллеров/баланса/allowlist
  (schemaVersion 1, ADR-0019 Решение 2)
- **`scripts/lib/md_code_mask.py`** (new) — общий примитив маскирования кода (fenced + inline)
- **`scripts/LICENSE.upstream.md`** (new) — атрибуция MIT порта (NFR-006)
- **Демаркация с W034** — `_KNOWN_TAGS` вычисляется из `gramax-render-rules.json`
  (drawio ∪ killerTags ∪ allowlistedTags); W034 молчит по `<th>`/`<colgroup>`/`<col>`
- **Дедуп баланса** — `check_tags` балансит только `pairedTags − balanceTags`
  (`html`, `comment`); unbalanced `note/tabs/tab/color/highlight` репортит рендер-линтер (FR-109)
- **Suite `tests/gramax/render-linter/`** (new) — 21 AC-тест (ac-001…ac-021), подключён
  шагом 14 к `check.sh --full`; рендер-линтер также шаг `--fast` на `content/`

Contract: `gramax-render-rules.json` — реестр киллеров рендера и allowlist «не ошибки».
Новый эмпирический киллер (BR-001) добавляется строкой в `killerTags` + CHANGELOG-запись
в том же коммите; вынос из allowlist — задокументированным решением, не правкой regex.

### Migration notes (рендер-линтер)

Потребителям pre-commit-хука: шаблон `scripts/pre-commit.sh` теперь вызывает ОБА валидатора
(`validate_structure.py` + `validate_render.py --errors-only`). Киллер рендера (например `<th>`)
блокирует коммит; WARN (H1 в теле) exit не меняет. Standalone `validate_structure.py` перестаёт
репортить unbalanced `note/tabs/tab/color/highlight` (ownership — в рендер-линтере) и W034 по
`<th>`/`<colgroup>`/`<col>` — см. `scripts/LICENSE.upstream.md` → «Список изменений».

### Migration notes (с v4.2.1)
- **W031** — проверка существования `.drawio`-файлов `<drawio path="..."/>` (`check_diagrams`)
- **W032** — no-ext резолв ссылок: `[link](target)` → `target.md` → `target/index.md`
- **W033** — проверка hash-якорей: `[link](article#section)` → существует ли заголовок
- **W034** — обнаружение неподдерживаемой HTML-разметки в markdown
- **`--groups`** — группированный вывод ошибок по таксономии CatalogErrorGroups
- **`lib/md_link_parser.py`** — унифицированный парсинг ссылок/изображений/drawio из markdown (5 unit tests)
- **`lib/link_resolver.py`** — no-ext + hash-якорь резолв со slugify (9 unit tests)
- **7 фикстур** в `tests/gramax/catalog-validator/fixtures/gramax-fixtures/`
- **7 AC-тестов** (ac-014–ac-020), suite расширен до 20 тестов

### Migration notes (с v4.2.1)

Потребителям `validate_structure.py` в CI: новые W030-W034 — WARNING, не ломают exit code.
При обновлении возможно появление новых предупреждений в логах — это ожидаемо. Для строгого
режима (exit code ≠ 0 на warnings) используйте `--strict`. Опциональный `--groups` меняет
формат вывода; без него вывод идентичен предыдущим версиям.

## 4.3.0 — 2026-08-12

Контракт формы ссылки на артефакт (ADR-0016): резолвер гейта учится инферить расширение цели, а
148 навигационных код-спанов корпуса мигрированы в markdown-ссылки по новой классификации
NAV/SELF/SUBJECT. Semver — Minor (ADR-0006, авторизовано ADR-0018 Решение 1): резолвер чисто
ослабляет существующую error-проверку (не может покрасить ранее зелёный каталог), миграция —
контентная правка формы ссылки, не меняющая структуру `.doc-root.yaml`-каталога или JSON-контракт.

Contract: `_collect_links` (`validate_structure.py`) — резолвер ссылок теперь инферит расширение
для целей без `.md`: пробует литерал → `target + ".md"` → `target + "/_index.md"`, использует
первый существующий путь (FR-082, ADR-0016 Решение 1). Ссылки, уже оканчивающиеся на `.md`
(включая антипаттерн `content/<section>/doc.md`), резолвятся буквально без изменений —
обратная совместимость сохранена (NFR-001).

### Added

- **`scripts/migrate_nav_codespans.py`** (new) — классификация NAV/SELF/SUBJECT код-спанов с
  путём (FR-077…081) и миграция NAV → markdown-ссылка `[title](relpath.md)`. Report-mode по
  умолчанию (без мутаций), `--fix --yes` — мутация с `--expect-count` guard'ом против расхождения
  пересчитанного числа кандидатов с ожидаемым (ADR-0016 Решение 5).

### Fixed

- `skills/writer/SKILL.md` — явный ❌/✅-пример антипаттерна FR-081 (повтор имени
  doc-root-каталога в тексте markdown-ссылки, форма `content/<section>/doc.md`).

### Migration notes

Резолвер (`_collect_links`) — единственное изменение поведения, видимое потребителям плагина: не
требует немедленных действий. Ссылки без расширения, ранее считавшиеся битыми, теперь резолвятся
корректно, если целевой `.md`/`_index.md` существует; ссылки, уже написанные с `.md`, резолвятся
как раньше. Миграция 148 навигационных код-спанов (145 при основном прогоне мигратора батчами по
подкаталогам + 3 добитых после независимой QA-runner находки в постмиграционных артефактах самой
волны) — внутренняя правка корпуса `content/` этого репозитория, потребителей плагина не касается
напрямую.

Временный протокол: результат миграции несёт явный `.md`-суффикс в тексте ссылки (не канонический
FR-080 «без расширения»), пока апстрим `tools-ai/nauta` (`check_broken_links`, дефект того же
класса) не научится инферить расширение самостоятельно — `SKILL.md` продолжает документировать
канонический синтаксис без расширения как целевой для внешних потребителей, расхождение временное
и локальное к тому, как этот репозиторий сам себя авторит (ADR-0016 Решение 2). Апстрим-issue
готовится отдельно.

## 4.2.1 — 2026-08-13

Ретракция нерабочего рецепта cross-каталожной ссылки через `code:`, опубликованного в 4.2.0
(ADR-0017, амендмент к диспозиции `2026-08-11-writer-rules-disposition.md`, Тема A / FR-065).
Исполняемый probe поверх немодифицированного `linkCreator.getLink()` движка Gramax установил:
рецепт **не работает** ни при каком внешнем сетапе — поле `code` резолвером ссылок нигде не
читается, это декоративное отображаемое имя каталога в UI (≤4 символа по форме настроек), не
идентификатор каталога-цели. Исправление документационное: ни один рабочий сценарий
потребителя не меняется и не ломается — рецепт никогда не резолвировался. Semver — Patch
(ADR-0006): исправление описания без изменения функциональности.

### Fixed

- `skills/writer/references/doc-root-schema.md` — раздел, представлявший `code:` как основу
  рабочего рецепта cross-каталожной ссылки, заменён честным объяснением декоративного
  назначения поля; строка `code` в таблице «Корневые ключи» больше не приписывает полю роль в
  резолве ссылок.
- `skills/writer/SKILL.md` (блок «## Ссылки») — снята ссылка на ретируемый рецепт; объяснение
  cross-каталожного правила исправлено фактически (движок не выходит за пределы каталога
  статьи-источника без `../`-префикса — не общее «markdown-ссылки между каталогами не
  резолвятся»); буллет, с первого коммита плагина противоречиво показывавший markdown-ссылку
  как форму cross-каталожной ссылки, приведён в соответствие с код-спан-примером в том же блоке.

Практическая рекомендация для cross-каталожных ссылок — inline code, не markdown-ссылка — не
изменилась и не требует действий от потребителей, уже ей следующих.

### Migration notes (с v4.2.0)

Если в твоём `.doc-root.yaml` объявлен `code:` и ты рассчитывал на него как на способ построить
резолвящуюся cross-каталожную ссылку (не просто UI-бейдж) — это ожидание не оправдается ни при
каком внешнем сетапе. Менять в своём контенте ничего не нужно — только не повторять рецепт
`code:` для новых ссылок. Если у тебя локальный скилл-дубль `writer` (тема F диспозиции
4.2.0), несущий копию этого рецепта, — пересинхронизируй его с этой версией
`doc-root-schema.md`.

## 4.2.0 — 2026-08-12

Валидатор каталога и mermaid-workflow получают машиночитаемый контракт вместо документации
прозой (ADR-0012), резолвится противоречие про `_index.md` в корне каталога (ADR-0015), а
принятие file-based mermaid у потребителей получает границу юрисдикции и инструмент пакетной
миграции (ADR-0013). Дополнительно задокументированы шесть повторяющихся потребительских
практик: cross-каталожные ссылки, статус ADR, XML-блоки как структура, дрейф локальных
скилл-дублей (`content/40-architecture/2026-08-11-writer-rules-disposition.md`). Semver —
Minor (ADR-0006): все изменения аддитивны, единственное ослабление существующей
error-проверки не может покрасить каталог, который раньше проходил валидацию.

Contract: `gramax-tags.json` v1, `gramax-catalog-rules.json` v1 (новые) — единственный
источник правды о поддерживаемых Gramax-тегах и правилах каталога; `validate_structure.py`
читает оба файла вместо собственных захардкоженных списков `PAIRED_TAGS`/`SELF_CLOSING`/
`GARBAGE_FILES` (ADR-0012 Решение 3). Семантика `indexPolicy.root` уточнена: `optional`
означает не «титульная страница», а «разрешён, но не отображается Gramax» (ADR-0015 Решение
4; подробности — раздел «Changed» ниже).

### Added

- **`gramax-tags.json`** (new) — единый список поддерживаемых Gramax-тегов: парных (`note`,
  `tabs`, `tab`, `html`, `comment`, `color`, `highlight`) и самозакрывающихся (`view`,
  `snippet`, `openapi`, `mermaid`, `video`, `icon`, `image`, `drawio`), плюс `legacy[]` —
  история устаревших форматов (старый drawio-тег `[drawio:...]`, устаревший inline-mermaid) с
  версией, в которой синтаксис перестал поддерживаться.
- **`gramax-catalog-rules.json`** (new) — единый список правил каталога: обязательные поля
  `.doc-root.yaml` и frontmatter, политика `_index.md` (`root: optional`, `subfolder:
  required`), служебные файлы, наименование и колокация non-md контента (`.mermaid`).
- **Три новые проверки `validate_structure.py`:** плейсхолдер шаблона `{{ИМЯ}}`, доехавший до
  наполненного каталога (error); статья-сирота без входящих markdown-ссылок внутри каталога
  (warning, error под `--strict`); битая markdown-ссылка на несуществующий файл (error).
  Ни одна из трёх не резолвит cross-каталожные ссылки между разными `.doc-root.yaml`-
  каталогами — такая ссылка не считается ни сиротой, ни битой ссылкой.
- **README:** новый раздел `## Валидация каталога` — среди первых заголовков `##`, со ссылками
  на оба JSON-контракта и на pre-commit-шаблон. `validate_structure.py --help` теперь тоже
  указывает, где искать документацию.
- **`scripts/pre-commit.sh`** (new) — готовый к копированию шаблон git pre-commit хука: вызывает
  `validate_structure.py` через `${CLAUDE_PLUGIN_ROOT}` на каталоге потребителя.
- **`scripts/migrate_mermaid.py`** (new) — офлайн-сканер и пакетный мигратор устаревшего
  inline-mermaid (`<mermaid>…</mermaid>`, fenced ` ```mermaid `) в file-based формат. По
  умолчанию — только отчёт (файл:строка + сводка `To-migrate`/`Out-of-jurisdiction`/
  `Already-compliant`), без изменения файлов; мутация — только под `--fix --yes`. Работает
  внутри границы юрисдикции — поддерева, чей ближайший предок несёт `.doc-root.yaml`; вне
  границы (инженерные документы репозитория) инлайн-mermaid не считается нарушением.
- `skills/mermaid/references/jurisdiction-and-validation.md` (new) — граница юрисдикции
  file-based mermaid с примерами, предикат «валидный `.mermaid`-файл» для собственного
  валидатора потребителя, пример расширения allowlist на `.mermaid`.
- `skills/writer/references/authoritative-source.md` (new) — как отличить легитимный локальный
  скилл-дубль потребителя (свои конвенции конкретного каталога) от нелегитимного
  (переизлагающего общее Gramax-правило поверх `writer` и объявляющего себя приоритетным при
  расхождении).
- `skills/writer/references/doc-root-schema.md` — рабочий пример cross-каталожной ссылки через
  `code`; явная позиция «вложенные `.doc-root.yaml` и overlay-расширение `properties` — вне
  периметра плагина, поведение не гарантируется»; проекция статуса ADR между телом статьи
  (источник истины) и frontmatter (обновляется тем же изменением).
- `skills/writer/references/structure.md` — раздел «XML-блоки, засчитываемые как структура»:
  `<note>`, `<tabs>`, `<view>`, `<snippet>`, `<mermaid>`, `<drawio>`, `<image>`, `<openapi>`.

### Changed

- **`_index.md` в корне каталога (рядом с `.doc-root.yaml`) больше не считается ошибкой
  валидатора** — проверка `check_no_index_in_root` удалена. Одновременно документация
  (`skills/writer/SKILL.md`, `references/structure.md`, `references/staging.md`,
  `references/doc-root-schema.md`) прямо формулирует: Gramax исключает корневой `_index.md` из
  чтения категории — файл разрешён, но не отображается ни как титульная страница, ни как
  раздел; навигация корня строится целиком из `.doc-root.yaml`. Это ослабление существующей
  error-проверки: каталог, ранее падавший на ней, теперь проходит, а у каталогов, которые уже
  проходили, поведение не меняется.
- `skills/writer/SKILL.md` — три точечные вставки: ловушка обратных кавычек рядом с правилом
  cross-каталожных ссылок (код-спан `` `[X](Y)` `` — не markdown-ссылка, чужой regex-валидатор
  может дать ложное срабатывание); guardrail утечки абсолютных путей (двойной риск —
  идентификация контрибьютора и битая ссылка); декларация `writer` как единственного
  authoritative-источника Gramax-соглашений плагина со ссылкой на новый
  `references/authoritative-source.md`.
- Self-closing tag листинги в документации writer-skill дополнены `<drawio/>`.

### Fixed

- `check_tags` (`validate_structure.py`) — ложное срабатывание `unpaired <tag>` на статьях,
  упоминающих Gramax-тег как inline-код в прозе (например, `` `<note>` `` в тексте, не сама
  разметка). Затрагивает любого потребителя, документирующего Gramax-теги прозой, не только
  этот репозиторий.

### Migration notes (с v4.1.x)

1. Замени собственную regex-таблицу Gramax-тегов чтением контракта — синхронизация с новым
   релизом плагина перестаёт требовать ручной правки на твоей стороне:
   ```bash
   jq -r '.pairedTags, .selfClosingTags' "${CLAUDE_PLUGIN_ROOT}/gramax-tags.json"
   ```
2. Если у тебя нет pre-commit-гейта для Gramax-каталога — скопируй готовый шаблон вместо того,
   чтобы писать свой валидатор с нуля:
   ```bash
   cp "${CLAUDE_PLUGIN_ROOT}/scripts/pre-commit.sh" .githooks/pre-commit
   chmod +x .githooks/pre-commit
   git config core.hooksPath .githooks
   ```
3. Мигрируй устаревший inline-mermaid в своём каталоге — сначала отчёт, затем правка:
   ```bash
   uv run "${CLAUDE_PLUGIN_ROOT}/scripts/migrate_mermaid.py" content
   uv run "${CLAUDE_PLUGIN_ROOT}/scripts/migrate_mermaid.py" content --fix --yes
   ```
4. Если твой собственный content-валидатор ограничивает проверяемые файлы суффиксом `.md` —
   расширь allowlist на `.mermaid`, иначе file-based диаграммы для него невидимы. Одного
   расширения allowlist недостаточно для проверки содержимого — предикат «валидный
   `.mermaid`-файл» см. `skills/mermaid/references/jurisdiction-and-validation.md`:
   ```python
   ALLOWED_SUFFIXES = {".md", ".mermaid"}
   ```
5. `_index.md` в корне каталога больше не ошибка валидатора плагина — и одновременно Gramax
   его не отображает: содержимое не попадает ни в титульную страницу, ни в список статей
   корня. Если в корневом `_index.md` лежит дашборд или контент, рассчитанный на читателя, —
   он остаётся видимым только в git-репозитории, не в интерфейсе Gramax; при необходимости
   перенеси такой контент в `_index.md` подраздела верхнего уровня, где Gramax его отображает.

## 4.1.1 — 2026-08-10

### Fixed

- `skills/writer/SKILL.md` — примеры и шаг 4 двухшагового workflow учили устаревшему тегу `[drawio:...]` / `<Image src=.../>`; заменено на канонический `<drawio path="..." width="..." height="..."/>`, введённый в 4.1.0. Расхождение с `references/drawio.md` и `references/blocks.md`, где формат уже был обновлён, устранено.
- `README.md` — та же правка тега в описании шага 2 drawio-workflow.
- `README.md` — добавлен `Warning` о конфликте триггеров с `Agents365-ai/mermaid-skill`, предписанный ADR-0008 «Решение 6» и не попавший в 2.0.0.

## 4.1.0 — 2026-05-12

### Changed
- **drawio**: формат тега в md изменён на `<drawio path="..." width="..." height="..."/>`
  (единый синтаксис вместо `[drawio:...]` для Markdown и `<Image.../>` для XML)

### Migration notes (с v4.0.0)
Старый тег: `[drawio:./file.svg:Описание:800px:600px]`
Новый тег: `<drawio path="./file.svg" width="800px" height="600px"/>`

## 4.0.0 — 2026-05-12

Breaking change. Mermaid skill переведён с inline-workflow на file-based: DSL теперь хранится в отдельном `.mermaid`-файле рядом со статьёй, а в md вставляется тег-ссылка `<mermaid path="…"/>`. Соответствует реальному формату Gramax, задокументированному в `blocks.md`.

### Breaking change

- `gramax:mermaid` больше не вставляет DSL inline в md-файл (`<mermaid>…</mermaid>` или ` ```mermaid … ``` `). Inline-подход несовместим с Gramax-рендером.
- Skill теперь создаёт два артефакта: `.mermaid`-файл (DSL) и тег-ссылку в md.
- Пользователи, строившие workflow на inline-вставке, должны адаптироваться к новому workflow (см. Migration notes ниже).

### Added

- **File-based workflow:** skill создаёт `.mermaid`-файл в той же директории, что и `target_page`, через Write tool. DSL содержит только чистый Mermaid (без обёрток).
- **Naming convention:** `<page-slug>-<diagram-slug>.mermaid`. Специальный кейс `_index.md` → `page-slug` берётся из родительской директории.
- **Коллизия имён:** при повторном вызове с уже существующим `.mermaid`-файлом skill читает первые 5 строк, информирует пользователя и предлагает три опции: перезаписать / выбрать другое имя / отменить. Без явного «перезаписать» — файл не трогается (NFR-001: идемпотентность).
- **Backward-compat предупреждение:** при обнаружении inline-блока `<mermaid>…</mermaid>` или fenced block ` ```mermaid … ``` ` в `target_page` — skill выводит предупреждение «устаревший формат» и предлагает миграцию. Не мигрирует молча.
- **Кириллица в slug:** при кириллической теме диаграммы skill предлагает семантический перевод на английский (не механическую транслитерацию).

### Changed

- `skills/mermaid/SKILL.md` — полная переработка: file-based workflow, naming convention, backward-compat, обновлённый fallback-диалог (mermaid-опция: «файл `.mermaid` рядом со статьёй, тег-ссылка в md»), расширенный checklist (добавлен пункт «файл не содержит Gramax-разметки»).
- `skills/mermaid/references/syntax-rules.md` — секция «Особенности Gramax» обновлена: file-based формат тега `<mermaid path="…"/>` вместо описания inline-блоков как основного формата.
- `.claude-plugin/plugin.json` — version `4.0.0`.
- `.claude-plugin/marketplace.json` — metadata.version `4.0.0`; descriptions обновлены.

### Default width/height

Из ground-truth `blocks.md`: `width="800px" height="450px"`. Пользователь может переопределить явно в запросе; если указан один параметр — второй берётся из default.

### Migration notes (с v3.x)

1. Обнови плагин: `/plugin update gramax` (или переустанови).
2. Все новые диаграммы создаются через file-based workflow автоматически.
3. Существующие inline-блоки в md-файлах **не затрагиваются автоматически**: при следующем обращении к статье skill предложит миграцию (извлечь DSL в `.mermaid`-файл и заменить блок на тег-ссылку).
4. При работе с git: после создания диаграммы через skill в commit входят два файла — `.mermaid` и изменённый md-файл со вставленным тегом.
5. Если Gramax-рендер не отображает диаграмму — проверь, что тег в md имеет форму `<mermaid path="./имя.mermaid" width="800px" height="450px"/>` (самозакрывающийся, путь относительный).

### ADR

- ADR-0010 (новый) — обоснование file-based workflow, naming convention, major bump 4.0.0, backward-compat scope, валидация DSL через checklist. Документ: `content/00-project/adr/0010-mermaid-file-based-workflow.md`.
- Частично supersedes ADR-0009 в части поведения mermaid skill (inline → file-based).

### Backward compatibility

- Имя skill'а `gramax:mermaid` не изменилось — явные триггеры работают.
- Skills `writer`, `comments-read`, `comments-write`, `drawio` и agent `review-agent` не затронуты.
- **Known limitation:** `gramax:mermaid-migrate` (пакетная миграция inline-блоков) не входит в scope v4.0.0. Планируется как Phase 2 при наличии реального запроса.

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
- ADR-0009 (новый) — обоснование удаления `claude-mermaid`, добавления `gramax:drawio`, keyword-стратегия description, процедура `git submodule deinit`. Документ: `content/00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md`.
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
