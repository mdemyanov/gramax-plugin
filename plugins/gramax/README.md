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
- `/gramax:mermaid` — генерация mermaid-диаграмм: создаёт `.mermaid`-файл рядом со статьёй и вставляет тег-ссылку в md
- `/gramax:plantuml` — генерация PlantUML/BPMN-диаграмм (включая Salt-макеты интерфейсов): создаёт `.puml`/`.bpmn`-файл рядом со статьёй и вставляет тег-ссылку в md; рендер — движок Gramax
- `/gramax:drawio` — drawio-диаграммы через внешний плагин `Agents365-ai/drawio-skill` (двухшаговый workflow)
- `/gramax:export` — экспорт DOCX/PDF (шаблоны, CLI, CI/CD) и сборка статического портала; исполнение — Node.js/`gramax-cli` в окружении пользователя

### Skill `comments-read` и `comments-write`

Комментарии Gramax живут парами файлов: позиция в `.md` и запись с тем же ID в `.comments.yaml` рядом (`_index.md` → `_index.comments.yaml`). Позиция в md пишется одной из трёх форм: inline-тег `<comment id="ID">фрагмент</comment>`, блочная XML-форма `<comment id="ID"/> … </comment>` и блочная скобочная `[comment:ID] … [/comment]`. Для каталогов с `syntax: XML` канон — XML-форма (её пишет визуальный редактор), скобочная — legacy, читается наравне. Один ID может стоять в md в нескольких позициях — это штатная конструкция движка: `comments-write` при удалении снимает все позиции ID, а `validate_comments.py` перечисляет номера строк информационной строкой. В ответе у автора под `user` пишется `id`, равный `mail`; ответ без `user.id` даёт предупреждение валидатора.

Триггеры: «покажи комментарии», «прочитай комментарии к документу», «добавь комментарий», «ответь на комментарий», «оставь комментарий».

### Skill `mermaid`

Генерирует mermaid DSL по словесному описанию, записывает его в отдельный `.mermaid`-файл рядом со статьёй и вставляет тег-ссылку `<mermaid path="…"/>` в md-документ. Без MCP-серверов и внешних зависимостей.

Триггеры: «нарисуй mermaid», «сгенерируй mermaid-диаграмму», «визуализируй процесс/архитектуру/цикл», «сделай flowchart/sequence/gantt/class/state/ER/pie/mindmap».

При запросе без явного движка («нарисуй диаграмму») задаёт уточняющий вопрос с четырьмя опциями: mermaid (`.mermaid`-файл + тег-ссылка), plantuml (`.puml`-файл + тег `<plant-uml path/>`), bpmn (`.bpmn`-файл + тег `<bpmn path/>`) или drawio (через внешний плагин, создаёт `.svg`). По умолчанию — mermaid.

**Пример результата:** для статьи `docs/auth/overview.md` с темой «процесс авторизации» skill создаёт `docs/auth/overview-auth-flow.mermaid` и вставляет в md тег `<mermaid path="./overview-auth-flow.mermaid" width="800px" height="450px"/>`.

Поддерживаемые типы: `flowchart`, `sequenceDiagram`, `gantt`, `classDiagram`, `stateDiagram-v2`, `erDiagram`, `pie`, `mindmap`.

Адаптировано из [axtonliu/axton-obsidian-visual-skills](https://github.com/axtonliu/axton-obsidian-visual-skills) (MIT) — см. `skills/mermaid/LICENSE.upstream.md`.

### Skill `plantuml`

Авторство PlantUML-диаграмм (включая Salt-макеты интерфейсов) и BPMN-процессов (Camunda XML): пишет исходник в `.puml`/`.bpmn`-файл рядом со статьёй и вставляет тег-ссылку `<plant-uml path="…"/>`/`<bpmn path="…"/>` в md. File-based канон и naming convention — единые с mermaid; без внешних зависимостей, скриптов и конвертаций. Рендер — серверный движком Gramax (рендер-сервис `DIAGRAM_RENDERER_SERVICE_URL`); рендер `<bpmn>` на проверенном окне движка не подтверждён — тег документирован по docs движка с оговоркой в навыке.

Триггеры: «нарисуй plantuml», «UML-диаграмма», «Salt», «макет интерфейса», «bpmn», «BPMN-процесс», «Camunda».

**Статус:** suite `tests/gramax/plantuml-bpmn` — 12 автотестов (AC-051…AC-062). Замер 2026-11-24
(`bash tests/gramax/plantuml-bpmn/run.sh`): 12 из 12 зелёные; из них AC-062 — композитный гейт
репозитория: зелёный ровно тогда, когда `bash scripts/check.sh --fast` завершается кодом 0.
Рендер BPMN/Salt заявлен движком, но runtime-проверка в живом окружении (GES — Gramax Enterprise
Server) не выполнялась: окно живых проверок закрыто документарно 2026-11-24 решением владельца D12
(дерево волны-4); живая сессия навыка (артефактные половины AC-051…AC-056, смоки AC-060 и AC-061)
тоже не проверялась. Вердикты «не проверено» с причинами —
`docs/60-implementation/acceptance/2026-11-24-ges-window-verdicts.md`, строки 1 и 3. Оговорка
выше сохраняется до измеренного вердикта.

### Skill `drawio`

Точка входа для явных drawio-запросов («нарисуй drawio», «drawio-схема», «.drawio-файл»). Не генерирует диаграммы самостоятельно — делегирует на внешний `Agents365-ai/drawio-skill` и описывает двухшаговый Gramax-workflow:

- Шаг 1: drawio-skill создаёт `.drawio` + `.svg` в рабочей директории.
- Шаг 2: вставь тег в md-страницу (writer-skill подскажет формат): `<drawio path="./diagram.svg" width="800px" height="600px"/>`.

**Установка внешнего плагина:**

```
/plugin marketplace add Agents365-ai/365-skills
/plugin install drawio
```

> **Warning:** Не устанавливайте `Agents365-ai/mermaid-skill` из 365-skills одновременно
> с `gramax:mermaid`. Оба skill'а описывают одинаковые триггеры (flowchart, sequence,
> gantt и др.) — Claude может выбрать не тот, поведение становится недетерминированным.
> Для drawio устанавливайте только `drawio` из 365-skills (не `mermaid`).

**Дополнительные зависимости** (требуются внешнему плагину):

- **draw.io desktop**: macOS — `brew install --cask drawio`; Linux — `.deb`/`.rpm` с [releases](https://github.com/jgraph/drawio-desktop/releases) (не используй snap — AppArmor блокирует запись файлов).
- **Python 3** — нужен для `repair_png.py` внутри drawio-skill; должен быть в PATH.

Детали Gramax-тегов для вставки — в справочнике writer-skill (файл `references/drawio.md`).

### Skill `export`

Экспорт документации Gramax в DOCX/PDF и сборка статического портала: авторство CSS-шаблона PDF (классы `.page`, `.title-page`, колонтитулы) и шаблона DOCX (`.docx`/`.dotx`), размещение шаблонов на портале, команда `npx gramax-cli export -f docx|pdf`, копируемая CI-стадия (`.gitlab-ci.yml` с `EXPORT_FILE_PATH`), статический портал через `npx gramax-cli build`. Граница исполнения: запуск требует Node.js и `gramax-cli` в окружении пользователя или CI-раннера — навык инструктирует и готовит артефакты, но не исполняет экспорт сам.

Триггеры: «экспорт», «DOCX», «PDF», «шаблон экспорта», «CI/CD», «статический портал».

## Валидация каталога

Плагин поставляет `scripts/validate_structure.py` — офлайн pre-publish валидатор
Gramax-каталога (обязательность `_index.md` в подпапках, парность тегов, frontmatter,
плейсхолдеры `{{ИМЯ}}`, статьи-сироты, битые markdown-ссылки). Правила и список
поддерживаемых Gramax-тегов — не в прозе, а в двух машиночитаемых JSON-контрактах рядом со
скриптом: [`gramax-tags.json`](./gramax-tags.json) и
[`gramax-catalog-rules.json`](./gramax-catalog-rules.json) — единственный источник правды,
который сам валидатор читает при каждом запуске (ADR-0012). Для подключения к pre-commit/CI
своего репозитория скопируйте готовый шаблон
[`scripts/pre-commit.sh`](./scripts/pre-commit.sh).

Строгость плейсхолдеров задана неодинаково, и это намеренно (ADR-0012, Решение 2). Этот
валидатор проверяет .doc-root.yaml и весь текст каждой статьи и выдаёт error без условия — коммит
блокирует и без --strict. Контур nauta проверяет плейсхолдеры своим validate-content.py
(проверка C7) только предупреждением, только во frontmatter статей и в .doc-root.yaml и только
для литералов вида {{ИМЯ_ЗАГЛАВНЫМИ}}. Источник истины по строгости проверок nauta — её
собственная документация вне этого репозитория; плагин её не повторяет и не меняет.

Начиная с 4.5.0 валидатор рекурсивно находит все `.doc-root.yaml` в дереве переданного
пути (не только в корне) и проверяет типы полей `.doc-root.yaml`: обязательны `title` и
`syntax`, `language` необязателен (с 4.10.0, ADR-0026); каждое из этих полей при наличии
обязано быть непустой строкой. Регресс-якорь — инцидент 2026-08-13:
незакавыченный `title: {{PROJECT_NAME}}` во вложенных `examples/`-каталогах ронял
редактор Gramax, тогда как валидатор давал exit 0 (ADR-0020).

Правила каталога с 4.10.0 (ADR-0026): `properties` в `_index.md` подпапки разрешены и
проверяются по схеме каталога так же, как в статьях (объявленность свойства, значение вне
enum, нотация); `_index.md` корня остаётся вне проверки. Флаг `optionalCategoryIndex: true`
в `.doc-root.yaml` снимает требование `_index.md` у подпапок — без него папка без
`_index.md` даёт ERROR. Коды иконок пишутся голым kebab-case (`check`, `zap`) и сверяются
с реестром встроенных кодов [`gramax-lucide-icons.json`](./gramax-lucide-icons.json):
предупреждение `W035` (иконка не найдена) возникает, только когда нет ни файла
`.icons/<код>.svg`, ни кода в реестре; код с префиксом `lucide-` даёт `W035` с подсказкой
убрать префикс, если код без префикса есть в реестре. Файл, не являющийся валидным UTF-8,
даёт одну именованную ошибку `E036` (путь, байт, позиция) у `validate_structure.py` и
`validate_comments.py`, а обход каталога продолжается.

Ссылки и абсолютные пути (ADR-0028): ссылка резолвится по цепочке «литеральный файл →
`цель.md` → `цель/_index.md`». Каталог без `_index.md` резолвится только при флаге
`optionalCategoryIndex: true` в `.doc-root.yaml`: без флага ссылка на такой каталог даёт
ERROR битой ссылки — «каталог без _index.md (раздела в дереве нет)», с флагом находки нет.
При одноимённых файле и каталоге (`section.md` и `section/`) ссылка `[Название](section)`
ведёт в файл. Абсолютный локальный путь контрибьютора в тексте статьи (`/Users/<имя>/…`,
`/home/<имя>/…`, `X:\Users\<имя>\…` с любой буквой диска, WSL
`/mnt/<буква>/Users/<имя>/…`; имя — любые буквы и цифры, включая не-латиницу), включая код,
даёт ERROR `E037` — по одной находке на строку; сообщение называет строку и форму с
фактической буквой диска, но не сам путь.

```bash
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py" content
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_structure.py" --help
```

Второй валидатор — `scripts/validate_render.py`: контент-линтер рендер-киллеров
(порт `validate-gramax.py`, MIT). Ловит подтверждённые замером киллеры рендера GES
(инлайновый `<note>…</note>`, многострочный `<colgroup>`) и ломающие вёрстку конструкции
(несколько `![](…)` в строке, несбалансированные парные теги
`note/table/tr/td/th/tabs/tab/color/highlight`) на уровне ERROR с номером строки и
подсказкой. `<th>` — WARN (потенциальный киллер апстрима, не подтверждённый на этой
цели по замеру 2026-11-21; несбалансированный `<th>` остаётся ERROR баланса), WARN-семантика
также у `<note>` внутри `<td>`/`<th>` и `<note>` в `<note>`. Стиль/YAML (`# H1` в теле,
frontmatter `title:` без кавычек) — WARN и exit не меняют.
Код (fenced **+ inline**) и содержимое блоков сырого HTML `<html>…</html>` исключаются из
проверок обоих валидаторов — примеры синтаксиса в прозе и легальные HTML-теги внутри блока
не считаются разметкой страницы. Теги `table`/`tr`/`td` известны и структурному валидатору
(предупреждения `W034` — неподдерживаемая разметка — на XML-таблицах нет), но баланс этих
тегов проверяет только этот линтер — один дефект, одна находка. Файл с битым UTF-8 даёт у
этого линтера одну ошибку
`ERROR L0: Файл не является валидным UTF-8 (байт 0xNN на позиции P из S)`, остальные файлы
проверяются (exit code 1). Реестр киллеров/баланса/allowlist — машиночитаемый контракт
[`gramax-render-rules.json`](./gramax-render-rules.json) (ADR-0019). Атрибуция источника —
[`scripts/LICENSE.upstream.md`](./scripts/LICENSE.upstream.md).

```bash
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_render.py" content
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/validate_render.py" --help
```

Pre-commit-хук этого плагина запускает оба валидатора (структурный + контент-линтер):
киллер рендера блокирует коммит, WARN-стиль через `--errors-only` не спамит.

Комментарии эти валидаторы не проверяют: команда по каталогу и способ включения в хук — в
`skills/comments-write/SKILL.md`, раздел «В каталоге и в цикле коммита».

Валидатор комментариев `validate_comments.py` с флагом `--strict` завершается с кодом 1 на
любом предупреждении — например, `dateTime not ISO 8601 UTC` или ответ без `user.id`; метки
находок остаются `WARNING`, уровень `info` не эскалируется. Без флага код выхода меняют
только ERROR.

Отдельно — `scripts/migrate_mermaid.py`: офлайн-сканер и пакетный мигратор устаревшего inline-mermaid (`<mermaid>…</mermaid>`, fenced ` ```mermaid `) в file-based формат внутри границы юрисдикции (`.doc-root.yaml`). По умолчанию — только отчёт (файл:строка + сводка из трёх счётчиков — `To-migrate`/`Out-of-jurisdiction`/`Already-compliant`), без единой мутации; мутация — только под `--fix --yes` (сводка тогда печатает `Migrated` вместо `To-migrate`). **Режим отчёта завершается ненулевым кодом, если найдены вхождения для миграции** — удобно как сигнал для CI, но учтите это заранее при вставке вызова в свой пайплайн, не выясняйте по красной сборке. Граница юрисдикции и предикат валидного `.mermaid`-файла для собственного валидатора потребителя — [`skills/mermaid/references/jurisdiction-and-validation.md`](./skills/mermaid/references/jurisdiction-and-validation.md).

```bash
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/migrate_mermaid.py" content
uv run "${CLAUDE_PLUGIN_ROOT}/scripts/migrate_mermaid.py" content --fix --yes
```

## Agents

- `review-agent` — координирует ревью комментариев в каталоге (запуск через Task tool)

## Scripts

Скрипты в `scripts/` доступны через `${CLAUDE_PLUGIN_ROOT}/scripts/...`:

- `slugify.py` — транслит кириллицы в latin-slug для имён файлов
- `validate_structure.py` — pre-publish валидация структуры каталога Gramax
- `validate_render.py` — контент-линтер рендер-киллеров (порт validate-gramax.py, MIT)
- `parse_comments.py` — парсинг и отчёт по комментариям
- `gen_comment_id.py` — генерация уникального ID комментария
- `validate_comments.py` — валидация парности `<comment>` ↔ `.comments.yaml`

## Версия

4.11.0 — см. [CHANGELOG.md](./CHANGELOG.md)
