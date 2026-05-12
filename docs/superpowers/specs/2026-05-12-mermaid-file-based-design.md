---
feature: mermaid-file-based
plugin: gramax
status: draft
created: 2026-05-12
---

# Mermaid skill — file-based workflow

## JTBD

Когда я работаю с Gramax-каталогом и мне нужно добавить диаграмму в статью через Claude Code, я (разработчик документации / технический писатель) хочу, чтобы `gramax:mermaid` создал отдельный `.mermaid`-файл рядом со статьёй и вставил правильный тег-ссылку в md, чтобы диаграмма отображалась корректно в Gramax-рендере без ручной правки файлов.

## Описание

Текущий mermaid skill (SKILL.md v3.0.0) генерирует DSL и вставляет его **inline** в md-файл — либо как `<mermaid>…</mermaid>`, либо как fenced block ` ```mermaid … ``` `. Это противоречит реальному формату Gramax, задокументированному в `blocks.md`: Gramax использует самозакрывающийся тег `<mermaid path="./diagram.mermaid" width="Wpx" height="Hpx"/>`, где DSL хранится в отдельном `.mermaid`-файле рядом со статьёй.

Расхождение между тем, что делает skill, и тем, что ожидает Gramax-рендер, означает, что каждая диаграмма, созданная через skill, требует ручного исправления — либо файл не отображается вовсе. Цель фичи — привести skill в соответствие с ground-truth форматом, описанным в `blocks.md`.

Новый workflow сохраняет все DSL-правила из текущего SKILL.md (syntax-rules, checklist, поддерживаемые типы, палитру) и меняет только способ хранения и вставки результата: DSL → файл, тег → ссылка. Поддерживаются оба каталог-синтаксиса Gramax (XML и Markdown): тег `<mermaid path=…/>` одинаков для обоих, потому что `.mermaid`-файл содержит чистый DSL без разметки.

## Функциональные требования

- **FR-001:** при активации `gramax:mermaid` skill определяет Gramax-синтаксис каталога из `.doc-root.yaml` (поле `syntax: XML | Markdown`) — обход вверх от `target_page`. Если `.doc-root.yaml` не найден — продолжает с предупреждением.
- **FR-002:** skill предлагает имя `.mermaid`-файла по naming convention (см. ниже) и спрашивает подтверждение / альтернативное имя у пользователя.
- **FR-003:** skill генерирует Mermaid DSL по правилам из `references/syntax-rules.md` и выполняет checklist перед записью (те же правила, что и сейчас).
- **FR-004:** skill создаёт `.mermaid`-файл в той же директории, что и `target_page`, через Write tool. Если файл с таким именем уже существует — skill предупреждает пользователя и запрашивает явное подтверждение перезаписи (не перезаписывает молча).
- **FR-005:** skill вставляет тег в md-файл (`target_page`):
  ```
  <mermaid path="./<filename>.mermaid" width="<W>px" height="<H>px"/>
  ```
  Тег самозакрывающийся, вставляется с пустой строкой до и после (независимо от syntax каталога XML/Markdown).
- **FR-006:** если в `target_page` уже есть inline-блок `<mermaid>…</mermaid>` или fenced block ` ```mermaid … ``` ` — skill обнаруживает это, предупреждает пользователя о формате-несоответствии и предлагает миграцию: извлечь DSL в `.mermaid`-файл и заменить блок на тег-ссылку. Не выполняет миграцию молча.
- **FR-007:** fallback-диалог при ambiguous-request (нет явного keyword «mermaid» / «drawio») обновляется: в описании mermaid-опции убирается фраза «inline DSL, без файла» и заменяется на «файл `.mermaid` рядом со статьёй, тег-ссылка в md».
- **FR-008:** unsupported типы (`gitGraph`, `journey`, `requirementDiagram`, `C4Context`) обрабатываются по прежней логике — предупреждение + предложение замены.

## Naming convention для .mermaid-файлов

Правило: `<page-slug>-<diagram-slug>.mermaid`

- `<page-slug>` — имя md-файла без расширения (если файл `_index.md` — имя родительской директории).
- `<diagram-slug>` — краткое тематическое имя диаграммы из запроса пользователя, kebab-case, ASCII, не более 30 символов.
- Пример: статья `auth-flow.md`, диаграмма «последовательность входа» → `auth-flow-login-sequence.mermaid`.
- Если пользователь не указал тему диаграммы — skill предлагает `<page-slug>-diagram.mermaid` как default.
- Символы, недопустимые в именах файлов (`:`, `*`, `?`, `"`, `<`, `>`, `|`, `\`) — заменяются на `-`.

## Default width/height

- **width:** `800px` (значение из `blocks.md`)
- **height:** `450px` (значение из `blocks.md`)

Пользователь может переопределить явно в запросе: «ширина 1200, высота 600» → `width="1200px" height="600px"`. Если указан только один параметр — второй берётся из default.

## Нефункциональные требования

- **NFR-001:** идемпотентность — повторный вызов с тем же именем файла не перезаписывает существующий `.mermaid`-файл без явного подтверждения пользователя (FR-004).
- **NFR-002:** совместимость с обоими синтаксисами каталога: тег `<mermaid path=…/>` вставляется одинаково для XML- и Markdown-каталогов; DSL в `.mermaid`-файле не содержит никакой разметки каталога.
- **NFR-003:** без внешних зависимостей и MCP — skill работает только через Write/Edit/Read tools Claude Code.
- **NFR-004:** токен-бюджет промпта не увеличивается относительно текущего SKILL.md — references подгружаются по требованию (только `syntax-rules.md` при ошибках, не при каждом вызове).
- **NFR-005:** работает на macOS и Linux; имена файлов — ASCII kebab-case (кириллица транслитерируется или запрашивается у пользователя).

## UX / интерфейс

**Команда:** `gramax:mermaid` (через slash-команду или авто-триггер по описанию диаграммы)

**Типовой диалог:**

1. Пользователь: «нарисуй mermaid-диаграмму процесса авторизации для статьи `docs/auth/overview.md`»
2. Skill: генерирует DSL, предлагает имя файла `overview-auth-flow.mermaid`, спрашивает подтверждение
3. Пользователь: подтверждает (или называет другое имя)
4. Skill: создаёт `docs/auth/overview-auth-flow.mermaid` (Write tool), вставляет в `overview.md` тег `<mermaid path="./overview-auth-flow.mermaid" width="800px" height="450px"/>`
5. Skill: сообщает пользователю, что сделано и какие файлы изменены

**Аргументы (опциональные, из текста запроса):**

| Параметр | Default | Пример |
|----------|---------|--------|
| `target_page` | спрашивает | `docs/auth/overview.md` |
| `diagram-slug` | `diagram` | `auth-flow` |
| `width` | `800px` | `1200px` |
| `height` | `450px` | `600px` |
| `direction` | `TB` | `LR` |
| `detail` | `standard` | `simple`, `detailed`, `presentation` |
| `style` | `professional` | `minimal`, `colorful`, `academic` |

**Формат вывода:** текст в stdout с подтверждением создания файла и вставки тега. Exit code 0 при успехе.

## Backward compatibility

**Кейс 1: в `target_page` уже есть inline `<mermaid>…</mermaid>`**

Skill обнаруживает блок при чтении файла и выводит:
```
Обнаружен inline-блок <mermaid>…</mermaid> в файле. Это устаревший формат — Gramax ожидает тег-ссылку <mermaid path="…"/>.
Предлагаю миграцию: извлечь DSL в файл <page-slug>-existing.mermaid и заменить блок на тег.
Выполнить миграцию? (да/нет)
```
Без подтверждения — не трогает файл.

**Кейс 2: в `target_page` уже есть fenced block ` ```mermaid … ``` `**

Аналогично кейсу 1 — предупреждение + предложение миграции.

**Кейс 3: файл `.mermaid` с предложенным именем уже существует**

Skill читает существующий файл, сообщает пользователю его содержимое (первые 5 строк) и спрашивает: перезаписать / выбрать другое имя / отменить.

## Затронутые файлы

- `plugins/gramax/skills/mermaid/SKILL.md` — полная переработка секций «Quick start», «Gramax-интеграция», «Workflow генерации», fallback-диалога.
- `plugins/gramax/skills/mermaid/references/syntax-rules.md` — обновить секцию «Особенности Gramax» (убрать описание inline-синтаксов как основного, добавить описание file-based).
- `plugins/gramax/CHANGELOG.md` — запись о breaking change (inline → file-based).
- `plugins/gramax/.claude-plugin/plugin.json` — bump версии (minor или major — решает SA/PM).

## Acceptance Criteria

- [ ] **AC-001:** при вызове `gramax:mermaid` с указанным `target_page` skill создаёт `.mermaid`-файл в той же директории, что и `target_page`; файл существует после выполнения: `test -f "$(dirname target_page)/diagram.mermaid"`.
- [ ] **AC-002:** содержимое созданного `.mermaid`-файла начинается с одного из 8 поддерживаемых типов (`flowchart`, `sequenceDiagram`, `gantt`, `classDiagram`, `stateDiagram-v2`, `erDiagram`, `pie`, `mindmap`): `head -1 diagram.mermaid | grep -qE "^(flowchart|sequenceDiagram|gantt|classDiagram|stateDiagram-v2|erDiagram|pie|mindmap)"`.
- [ ] **AC-003:** `target_page` содержит тег `<mermaid path="./…" …/>` после вставки: `grep -q '<mermaid path="./' target_page.md`.
- [ ] **AC-004:** тег в md содержит атрибуты `width` и `height`: `grep -q 'width="' target_page.md && grep -q 'height="' target_page.md`.
- [ ] **AC-005:** тег в md использует значения по умолчанию `width="800px" height="450px"`, если пользователь не задал явно: `grep -q 'width="800px" height="450px"' target_page.md`.
- [ ] **AC-006:** тег в md является самозакрывающимся (без содержимого между тегами): `grep -q '<mermaid path="[^"]*" width="[^"]*" height="[^"]*"/>' target_page.md`.
- [ ] **AC-007:** файл `.mermaid` не содержит Gramax XML-разметки (`<mermaid>`, fenced block): `! grep -qE '^(<mermaid>|```mermaid)' diagram.mermaid`.
- [ ] **AC-008:** при повторном вызове с тем же именем файла, если файл существует, skill не перезаписывает его без подтверждения — после второго вызова с ответом «нет» на перезапись файл содержит оригинальный DSL: содержимое файла не изменилось.
- [ ] **AC-009:** при наличии в `target_page` inline-блока `<mermaid>…</mermaid>` skill выводит предупреждение с подстрокой «устаревший формат» или «migration» в stdout — проверяется smoke-тестом, подставляющим преднамеренно некорректный файл: `output=$(run_mermaid_skill …); echo "$output" | grep -qi "устаревший\|migration"`.
- [ ] **AC-010:** чекбоксы checklist (FR-003) применяются к DSL в `.mermaid`-файле: в созданном файле нет паттерна `[0-9]\. ` (конфликт list-syntax): `! grep -qP '\[\d+\. ' diagram.mermaid`.
- [ ] **AC-011:** fallback-диалог при ambiguous-request не содержит фразу «inline DSL, без файла»: `! grep -q 'inline DSL, без файла' plugins/gramax/skills/mermaid/SKILL.md`.

## Открытые вопросы

- **Q-001 (bump версии):** является ли переход с inline на file-based breaking change (требует major bump 3.x → 4.0) или достаточно minor (3.0 → 3.1)? Решает SA/PM с учётом политики совместимости.
- **Q-002 (транслитерация):** нужна ли автоматическая транслитерация кириллицы в `<diagram-slug>` или достаточно запросить у пользователя ASCII-имя?
- **Q-003 (migration scope):** нужен ли отдельный skill/команда `gramax:mermaid-migrate` для пакетной миграции всех inline-блоков в каталоге, или достаточно per-file предупреждения?
- **Q-004 (preview):** нужна ли проверка валидности DSL до записи файла (например, через внешний mermaid-cli)? Текущая NFR-003 запрещает внешние зависимости, поэтому — только статический checklist.
- **Q-005 (width/height discovery):** стоит ли добавить эвристику для выбора height на основе числа нод/строк DSL, или оставить фиксированный default?

---

## Бриф для SA

**Spec:** `docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md`

**Спроектировать:**

1. Изменения в `plugins/gramax/skills/mermaid/SKILL.md`: переход с inline-workflow на file-based; сохранение DSL-правил; новый fallback-текст.
2. Изменения в `references/syntax-rules.md`: секция «Особенности Gramax» — замена описания inline-форматов на file-based.
3. Bump версии в `plugin.json` и `CHANGELOG.md`: определить, является ли изменение breaking (major) или minor.
4. Нужна ли отдельная skill/команда для batch-миграции inline-блоков (Q-003).

**Бизнес-правила (инварианты):**

- DSL-правила (checklist, syntax-rules, поддерживаемые типы) не меняются.
- Файл `.mermaid` хранится рядом со страницей — не в отдельной папке assets.
- Тег `<mermaid path="…"/>` одинаков для XML- и Markdown-каталогов.
- Skill не перезаписывает существующий `.mermaid`-файл без явного подтверждения.

**Acceptance Criteria для проверки архитектуры:** AC-001…AC-011 из spec выше.
