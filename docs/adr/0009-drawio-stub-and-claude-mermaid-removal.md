# ADR-0009: Drawio-stub skill и удаление submodule claude-mermaid

**Status:** Accepted
**Date:** 2026-05-11
**Plugin:** gramax / marketplace

## Context

Spec `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md` описывает фичу **routing-mermaid-drawio v3.0.0**:

- Добавить явный skill `gramax:drawio` (заглушка-делегатор) с точными description-формулировками и уточняющим вопросом при неоднозначном запросе.
- Удалить vendored submodule `plugins/claude-mermaid/` — он создаёт конфликт триггеров с `gramax:mermaid`.
- Поднять версию до 3.0.0 (major: удаление публичного vendored-плагина из marketplace).
- Уточнить description `gramax:mermaid`: убрать упоминание `Agents365-ai/mermaid-skill` как конфликтующего, добавить cross-ref на `gramax:drawio`.

Директива пользователя (2026-05-11): «используем только gramax:mermaid и drawio, уточни описание скилов и я хочу, чтобы ты добавил заглушку для drawio — gramax:drawio. Пользователь либо явно указывает инструмент, либо навык уточняет какой».

**Связь с предшествующими ADR:**

- **ADR-0008** (Accepted) — установил делегирование drawio на `Agents365-ai/drawio-skill` и двухшаговый Gramax-workflow. Данный ADR-0009 расширяет этот паттерн, добавляя явный skill-entry-point для drawio внутри плагина gramax. ADR-0008 остаётся Active.
- **ADR-0004** (Superseded by ADR-0008) — отверг router-skill как паттерн (двойной LLM-hop, токен-бюджет). OQ-001 требует reconciliation: решение ниже не создаёт router-skill.
- **ADR-0006** (Active) — semver-policy: удаление компонента marketplace = major bump.

**7 открытых вопросов из spec (OQ-001—OQ-007):** все закрываются данным ADR.

---

## Решение 1 — OQ-001: Где живёт логика уточняющего вопроса?

**Выбран вариант B:** только `gramax:mermaid` ловит generic-триггеры («нарисуй диаграмму», «визуализируй процесс»); `gramax:drawio` — только explicit drawio-триггеры. При неявном запросе `gramax:mermaid` является единственным владельцем generic-триггеров и задаёт уточняющий вопрос.

**Reconciliation с ADR-0004:** ADR-0004 отверг _router-skill_ — отдельный SKILL.md, активирующийся на любой diagram-запрос и делегирующий в backend-skills (двойной LLM-hop). Вариант B — принципиально иное: `gramax:mermaid` является самостоятельным исполняющим skill'ом, который при неявном запросе выполняет одно уточняющее действие в том же ответе, а не делегирует. Нет отдельного router-артефакта, нет двойного hop.

**Обоснование выбора B над альтернативами:**

- Вариант A (оба skill'а ловят generic-триггеры) — конфликт: при запросе «нарисуй диаграмму» Claude может активировать любой из двух skill'ов недетерминированно.
- Вариант C (drawio ловит generic-триггеры) — нежелателен: drawio-skill является заглушкой-делегатором с внешней зависимостью, делать её default для неявных запросов увеличивает onboarding-friction.
- Вариант D (уточнение в writer/SKILL.md) — writer не всегда активен; логика принадлежит diagram-domain, не writer-domain.

**Поведение при неявном запросе (алгоритм для SKILL.md mermaid):**

> Если запрос не содержит явного engine-keyword («mermaid», «drawio», «.drawio»):
> — задай вопрос: «Какой движок использовать?»
>   1. **mermaid** — inline DSL, без файла, без preview; рендер Gramax-фронтендом.
>   2. **drawio** — через внешний плагин `Agents365-ai/drawio-skill`; создаёт `.svg`-файл.
> — по умолчанию (если пользователь не выбрал явно) — mermaid.

**Контракт поведения:** уточняющий вопрос при неявном запросе — это best-effort, не гарантированный контракт (зависит от skill-activation Claude). Единственный гарантированный детерминизм — явный engine-keyword в запросе (OQ-006).

---

## Решение 2 — OQ-002: Процедура `git submodule deinit` для claude-mermaid

Текущий статус в worktree: submodule зарегистрирован в `.gitmodules` (запись `[submodule "plugins/claude-mermaid"]`), commit `-817759b9b79eec7e365b9c18b5b14d870ef3ea9c plugins/claude-mermaid` (дефис = не инициализирован).

**Точная последовательность команд для Dev (выполнять в корне worktree):**

```bash
# 1. Deinit — убирает запись из .git/config, не трогает файлы
git submodule deinit -f plugins/claude-mermaid

# 2. Удаление из индекса git и физически из рабочего дерева
git rm -rf plugins/claude-mermaid

# 3. Удаление cached modules (если были инициализированы ранее)
rm -rf .git/modules/plugins/claude-mermaid

# 4. Проверить .gitmodules — запись должна быть удалена шагом 2 автоматически.
#    Если осталась — удалить вручную секцию [submodule "plugins/claude-mermaid"].
grep 'claude-mermaid' .gitmodules && echo "WARN: запись осталась, удалить вручную" || echo "OK"

# 5. Удаление entry из .claude-plugin/marketplace.json (см. Решение 3)
```

**Важно:** submodule не инициализирован в worktree (дефис перед commit-хэшем), поэтому `git submodule deinit` может вернуть «не инициализирован» — это нормально, шаги 2–4 обязательны в любом случае.

---

## Решение 3 — OQ-003: Major bump 3.0.0

**Решение подтверждено.** Удаление vendored плагина `claude-mermaid` из публичного `marketplace.json` является breaking change по ADR-0006:

- Пользователи, установившие marketplace через `mdemyanov/gramax-plugin`, ожидали наличия `claude-mermaid` в каталоге.
- Удаление entry = потеря функциональности (`mermaid_preview`, `mermaid_save` MCP-tools).

Исключение (minor вместо major) неприменимо: ADR-0006 явно: «удаление компонента = major».

**Синхронный bump обоих файлов в одном коммите (конвенция ADR-0006):**

| Файл | Было | Станет |
|------|------|--------|
| `plugins/gramax/.claude-plugin/plugin.json` → `version` | `"2.0.0"` | `"3.0.0"` |
| `.claude-plugin/marketplace.json` → `metadata.version` | `"2.0.0"` | `"3.0.0"` |

---

## Решение 4 — OQ-004: MCP в settings.json пользователя

`claude-mermaid` поставлял MCP-сервер (`mermaid_preview`, `mermaid_save`). Часть пользователей могла добавить его вручную в локальный `~/.claude/settings.json` или `.claude/settings.json` проекта.

**Формулировка для migration notes в CHANGELOG.md:**

> После `/plugin update gramax` или переустановки плагина:
> 1. Проверь `~/.claude/settings.json` на наличие записи в `mcpServers` с ключом `mermaid` (или `claude-mermaid`).
> 2. Если запись есть — удали её вручную: MCP-сервер `claude-mermaid` более не входит в marketplace.
> 3. Если Claude Code сообщает об ошибке «MCP server not found» для mermaid — это следствие удаления; инструмент больше не нужен: `gramax:mermaid` работает без MCP.

**Примечание:** плагин не имеет доступа к локальным settings.json пользователей — инструкция информационная, не автоматическая.

---

## Решение 5 — OQ-005: Точные description-формулировки

**Принцип работы description в Claude Code:** description читается как семантический hint для skill-activation, не как regex. Claude выбирает skill по близости description к запросу. Explicit engine-keyword — единственный гарантированный способ детерминированного выбора. Anti-triggers и cross-ref снижают вероятность ложного срабатывания, но не исключают его полностью.

### description для `gramax:mermaid` (точный текст для SKILL.md frontmatter)

```
Только для диаграмм в синтаксисе Mermaid DSL — НЕ для drawio. Создание mermaid-диаграмм
для документации Gramax по текстовому описанию. Используй когда: «нарисуй mermaid»,
«mermaid-диаграмма», «сгенерируй mermaid flowchart/sequence/gantt/class/state/ER/pie/mindmap»,
«визуализируй процесс/архитектуру» (без указания движка — уточнит сам).
Не для: drawio, .drawio-файлов, SVG-схем через drawio — используй gramax:drawio.
Для drawio → gramax:drawio.
```

**Изменение относительно текущего SKILL.md:** убрать упоминание `Agents365-ai/mermaid-skill` как конфликтующего (теперь разграничение через `gramax:drawio`); добавить explicit generic-триггеры («визуализируй процесс/архитектуру» без движка); добавить cross-ref `gramax:drawio` в обоих местах (`description` frontmatter и секция «Не для»).

### description для `gramax:drawio` (точный текст для SKILL.md frontmatter)

```
Только для drawio-диаграмм — НЕ для mermaid. Точка входа для создания drawio-схем в Gramax.
Используй когда: «нарисуй drawio», «drawio-схема», «drawio-диаграмма», «схема drawio»,
«сделай .drawio-файл», «нарисуй диаграмму drawio».
Не для: mermaid DSL, flowchart/sequence/gantt без упоминания drawio — используй gramax:mermaid.
Для mermaid → gramax:mermaid.
Делегирует генерацию на внешний плагин Agents365-ai/drawio-skill; при неустановленном плагине
выводит команды установки.
```

**Anti-trigger логика:** `gramax:drawio` не должен активироваться на «нарисуй flowchart» без «drawio» — поэтому в description явно указано «flowchart/sequence/gantt без упоминания drawio → gramax:mermaid».

---

## Решение 6 — OQ-006: Контракт «явный engine vs неявный»

**Операционная семантика:**

| Тип запроса | Поведение | Уровень гарантии |
|-------------|-----------|-----------------|
| Явный mermaid: «нарисуй mermaid flowchart» | `gramax:mermaid` активируется, выполняет сразу | Детерминированный (keyword-match в description) |
| Явный drawio: «нарисуй drawio-схему» | `gramax:drawio` активируется, выводит workflow/установку | Детерминированный |
| Неявный: «визуализируй процесс», «нарисуй диаграмму» | `gramax:mermaid` активируется (единственный владелец generic-триггеров), задаёт уточняющий вопрос | Best-effort |

**Алгоритм уточнения (для секции SKILL.md mermaid «Fallback при ambiguous-request»):**

```
Если в запросе нет ключевых слов «mermaid», «drawio», «.drawio»:

  Задай вопрос пользователю:

  «Какой движок использовать для диаграммы?
   1. mermaid — inline DSL, без файла, без preview; рендер Gramax-фронтендом.
   2. drawio — через внешний плагин (нужна установка Agents365-ai/drawio-skill);
      создаёт .svg-файл рядом со страницей.

  По умолчанию — mermaid, если не укажешь.»

После ответа пользователя — выполнить соответствующий путь без повторного вопроса.
```

**Поведение при неявном запросе — best-effort, не контракт:** Claude может активировать `gramax:drawio` вместо `gramax:mermaid` при generic-запросе, если оба skill'а установлены. Полный детерминизм достигается только явным указанием engine в запросе. Это зафиксировано как known limitation в CHANGELOG.md и README.

---

## Решение 7 — OQ-007: Scope `gramax:drawio` skill'а

**Решение: полноценный SKILL.md**, а не минимальная декларация в plugin.json.

**Обоснование:**
- Skill должен содержать инструкции по установке внешнего плагина (FR-004) — это не помещается в `description` plugin.json.
- Skill описывает двухшаговый Gramax-workflow (FR-005) — требует структурированного изложения.
- Skill документирует уточняющий вопрос при ambiguous-запросе (FR-006) — нужен алгоритм.
- Skill является коротким (≤200 строк / ≤2000 токенов по NFR-001) — без скриптов, без MCP.

**Структура `plugins/gramax/skills/drawio/SKILL.md` (секции и содержание для Dev):**

```markdown
---
name: drawio
description: "<точный текст из Решения 5>"
---

# Drawio для Gramax

Краткое: заглушка-делегатор на Agents365-ai/drawio-skill. Сам не генерирует.

## When to use
Явные drawio-запросы: «нарисуй drawio», «drawio-схема», «.drawio-файл».
НЕ для mermaid (→ gramax:mermaid).

## Prerequisites
Установка внешнего плагина:
  /plugin marketplace add Agents365-ai/365-skills
  /plugin install drawio
+ draw.io desktop + Python 3 (требования внешнего плагина).

## Workflow (двухшаговый)
Шаг 1: вызови drawio-skill — создаст .drawio + .svg в CWD.
Шаг 2: вставь тег в md-страницу (writer-skill подскажет формат):
  [drawio:./diagram.svg:Описание:800px:600px]  # Markdown-syntax
  <Image src="./diagram.svg" alt="Описание" /> # XML-syntax

## Gramax-теги
Markdown: [drawio:./file.svg:alt:WxHpx]
XML: <Image src="./file.svg" alt="..." />
Примечание: drawio-skill не знает о .doc-root.yaml, не вставляет тег автоматически.

## Fallback при ambiguous-request
Если пользователь не указал движок явно — задать вопрос (алгоритм из Решения 6).

## Не для
- Mermaid DSL → gramax:mermaid
- Preview диаграмм в браузере
```

---

## Изменения статусов ADR

| ADR | Текущий статус | После ADR-0009 |
|-----|----------------|----------------|
| 0008 | Accepted | Без изменений (ADR-0009 дополняет, не отменяет) |
| 0006 | Active | Без изменений (применён в Решении 3) |
| 0004 | Superseded by ADR-0008 | Без изменений |
| 0001—0003, 0005, 0007 | Superseded/Historical | Без изменений |

**Правило:** согласно конвенции репозитория (ADR supersede-процедура из CLAUDE.md) — старые ADR не редактируются. Смена статусов существующих ADR — отдельная задача PM с explicit sign-off.

---

## Список изменений в коде (для Dev, actionable)

Порядок: failing stubs (QA-author) → реализация → smoke зелёный.

1. **`plugins/gramax/skills/drawio/SKILL.md`** — создать (структура из Решения 7, description из Решения 5).

2. **`plugins/gramax/skills/mermaid/SKILL.md`** — обновить description frontmatter (Решение 5): убрать упоминание `mermaid-skill` как конфликтующего; добавить generic-триггеры; добавить cross-ref `gramax:drawio`; добавить секцию/алгоритм уточняющего вопроса (Решение 6).

3. **`plugins/gramax/.claude-plugin/plugin.json`** — добавить skill `drawio` в секцию `skills`; bump `version` → `"3.0.0"`.

4. **`plugins/claude-mermaid/`** — удалить submodule (процедура из Решения 2, 5 шагов).

5. **`.gitmodules`** — убрать запись `[submodule "plugins/claude-mermaid"]` (шаг 2 `git rm` должен сделать это автоматически; проверить).

6. **`.claude-plugin/marketplace.json`** — убрать entry `claude-mermaid`; bump `metadata.version` → `"3.0.0"`; обновить `metadata.description` и `plugins[gramax].description` (убрать упоминания claude-mermaid, добавить drawio skill).

7. **`plugins/gramax/CHANGELOG.md`** — добавить секцию `## 3.0.0` с подразделами Added / Removed / Changed / Migration (включая инструкции OQ-004 по MCP из Решения 4).

8. **Orphan-ссылки (sunset pattern)** — grep `claude-mermaid` по всем `.md`/`.json` файлам плагина. Файлы, требующие правки (кроме docs/adr/ и docs/superpowers/ — исторический контекст):
   - `README.md` — упоминает claude-mermaid, требует обновления.
   - `CHANGELOG.md` (корневой) — упоминает claude-mermaid, требует обновления.
   - `AGENTS.md` — упоминает claude-mermaid, проверить.
   - `plugins/gramax/skills/mermaid/LICENSE.upstream.md` — содержит упоминание, проверить (возможно исторический контекст — не трогать).
   - `.claude-plugin/marketplace.json` — покрыт пунктом 6.

9. **`bash scripts/check.sh --fast`** — зелёный (AC-014).

**Синхронность:** пункты 4, 5, 6 (submodule removal + marketplace.json) выполнять в одном коммите. Пункты 3, 6 (version bump) — синхронно (ADR-0006).

---

## Consequences

**Положительные:**
- Явный `gramax:drawio` устраняет путаницу: пользователь всегда знает, через какой skill запрашивать drawio.
- Удаление `claude-mermaid` submodule убирает конфликт триггеров с `gramax:mermaid`.
- Description mermaid очищен от устаревшего предупреждения про `mermaid-skill` (теперь разграничение через `gramax:drawio`).
- Skill-архитектура становится плоской (2 skill'а без router), что соответствует ADR-0004.

**Отрицательные / trade-offs:**
- Breaking change для пользователей `claude-mermaid` (MCP preview/save теряется).
- Generic-триггеры без engine-keyword не детерминированы — best-effort, не контракт (known limitation).
- `gramax:mermaid` берёт на себя роль «диспетчера» generic-запросов — slight scope expansion, но без создания отдельного router-артефакта.

**Mitigations:**
- Migration notes в CHANGELOG.md § 3.0.0 покрывают все три breaking-кейса (MCP, claude-mermaid, generic-triggers).
- Явные anti-triggers и cross-ref в description снижают вероятность ложного срабатывания.
- Пользователям рекомендуется всегда указывать engine явно в запросе.

---

## Risks / Trade-offs

**RISK-001: Generic-trigger недетерминизм.** При запросе «нарисуй диаграмму» Claude может активировать `gramax:drawio` вместо `gramax:mermaid`, несмотря на description-разграничение. Mitigation: документировать как known limitation; рекомендовать явный engine в README.

**RISK-002: Orphan-ссылки после submodule removal.** Файлы, ссылающиеся на `claude-mermaid`, не обновлённые Dev'ом, создадут broken references. Mitigation: Dev выполняет grep-sweep (пункт 8 списка изменений); QA проверяет AC-009/AC-010/AC-011.

**RISK-003: Субmodule не инициализирован в worktree.** `git submodule deinit` может вернуть предупреждение. Mitigation: Dev следует точной последовательности из Решения 2 — шаги 2–4 обязательны независимо от статуса инициализации.

**RISK-004: Версионный drift.** Если `plugin.json` и `marketplace.json` обновлены в разных коммитах. Mitigation: pm-review checklist; Dev обновляет оба в одном коммите.

---

## Alternatives Considered

- **Вариант A (оба skill'а ловят generic-триггеры)** — отклонён: недетерминированный конфликт при generic-запросе.
- **Вариант C (drawio как default для generic)** — отклонён: drawio-stub с внешней зависимостью не должен быть default'ом; увеличивает onboarding-friction.
- **Вариант D (уточнение в writer/SKILL.md)** — отклонён: writer не всегда активен; логика принадлежит diagram-domain.
- **Минимальная декларация drawio в plugin.json без SKILL.md** — отклонено: невозможно вместить инструкции по установке, двухшаговый workflow и алгоритм уточнения в поле `description` plugin.json.
- **Сохранение claude-mermaid submodule** — отклонено: конфликт триггеров с `gramax:mermaid` не устраняется; директива пользователя явна.

---

## Контракт с QA-author

**AC (полный список из spec):** AC-001—AC-015 (все проверяемы shell-командами, см. spec §Acceptance Criteria).

**Архитектурный контекст:**
- Скоуп создания: `plugins/gramax/skills/drawio/SKILL.md`
- Скоуп обновления: `plugins/gramax/skills/mermaid/SKILL.md`, `plugins/gramax/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/gramax/CHANGELOG.md`
- Скоуп удаления: `plugins/claude-mermaid/` (submodule), `.gitmodules` entry
- External boundaries: git submodule state, JSON-манифесты, файловая система

**Edge cases / boundary conditions:**
- Submodule может быть не инициализирован (статус `-`) — AC-009/AC-010 должны проверять отсутствие как каталога, так и `.gitmodules`-записи.
- `grep -c` на `description` в SKILL.md может дать false positive, если слово «drawio» встречается в секции «Не для» — AC-003 формулировать через контекст (frontmatter, не весь файл).
- AC-007 (отсутствие `mermaid-skill` в mermaid SKILL.md): текущий SKILL.md уже не содержит этой строки — тест должен пройти без правок, но Dev должен убедиться.
- `bash scripts/check.sh --fast` (AC-014) может упасть, если в check.sh есть hard-coded пути к удалённым артефактам — QA проверяет сам check.sh.

**Test-pyramid:**

| AC | Уровень | Обоснование |
|----|---------|-------------|
| AC-001, AC-010 | smoke | `test -f` / `test ! -d` — file-system |
| AC-002 | manifest-validation | JSON-парсинг `plugin.json`, поле `skills` |
| AC-003, AC-004, AC-005, AC-006 | smoke | `grep` на SKILL.md drawio |
| AC-007, AC-008 | smoke | `grep` на SKILL.md mermaid |
| AC-009 | smoke | `grep` на `.gitmodules` |
| AC-011 | manifest-validation | JSON-парсинг `marketplace.json`, массив `plugins` |
| AC-012 | manifest-validation | JSON-парсинг `plugin.json`, поле `version` |
| AC-013 | smoke | `grep` на `CHANGELOG.md` |
| AC-014 | smoke | `bash scripts/check.sh --fast` — интеграционный |
| AC-015 | smoke | `wc -l` на `drawio/SKILL.md` |

---

## Бриф для Dev

**Spec:** `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md`
**ADR:** `docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md`

**Реализовать в порядке:**

1. `plugins/gramax/skills/drawio/SKILL.md` — создать (структура из Решения 7).
2. `plugins/gramax/skills/mermaid/SKILL.md` — обновить description и добавить секцию fallback (Решения 5, 6).
3. `plugins/gramax/.claude-plugin/plugin.json` — добавить skill `drawio`, bump `3.0.0`.
4. `plugins/claude-mermaid/` — удалить submodule (точная процедура из Решения 2).
5. `.claude-plugin/marketplace.json` — убрать claude-mermaid entry, bump `3.0.0`, обновить descriptions.
6. `plugins/gramax/CHANGELOG.md` — секция `## 3.0.0` (Added/Removed/Changed/Migration).
7. Orphan-ссылки — grep + правка (пункт 8 списка изменений).
8. `bash scripts/check.sh --fast` — зелёный.

**Acceptance Criteria:** AC-001—AC-015 (все).

---

## Связанные артефакты

- spec: `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md`
- дополняет: `docs/adr/0008-drop-internal-drawio-skills.md` (не supersedes)
- reconciles (в части OQ-001): `docs/adr/0004-router-and-engine-selection.md` (Superseded by ADR-0008)
- применяет semver-policy: `docs/adr/0006-marketplace-json-semver-strategy.md`
- затрагивает: `plugins/gramax/skills/drawio/` (new), `plugins/gramax/skills/mermaid/SKILL.md`, `plugins/gramax/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/gramax/CHANGELOG.md`, `plugins/claude-mermaid/` (removed), `.gitmodules`
