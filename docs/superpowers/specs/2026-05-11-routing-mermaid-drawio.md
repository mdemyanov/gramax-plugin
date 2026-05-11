---
title: Routing mermaid/drawio v3.0.0 — два явных skill'а + уточняющий вопрос
status: draft
date: 2026-05-11
plugin: gramax
---

# Routing mermaid/drawio v3.0.0

## Goal

Устранить путаницу в роутинге диаграмм: два явных skill'а (`gramax:mermaid`, `gramax:drawio`) с уточнёнными description'ами, плюс заглушка `drawio` которая делегирует к внешнему плагину и уточняет движок при неоднозначном запросе.

## JTBD

**Story 1 — явный mermaid-запрос:**
Когда я прошу «нарисуй mermaid flowchart для процесса деплоя», я (разработчик документации) хочу, чтобы `gramax:mermaid` активировался сразу без уточняющих вопросов и вернул готовый DSL-блок для вставки в md-страницу, чтобы не тратить время на диалог о выборе движка.

**Story 2 — явный drawio-запрос (внешний плагин установлен):**
Когда я прошу «нарисуй drawio-схему архитектуры» и у меня установлен `Agents365-ai/drawio-skill`, я (разработчик документации) хочу, чтобы `gramax:drawio` активировался сразу и передал управление drawio-skill с напоминанием о двухшаговом Gramax-workflow (drawio-skill создаёт `.svg` → writer-skill вставляет тег), чтобы получить корректный файл и не забыть шаг вставки тега.

**Story 3 — явный drawio-запрос (внешний плагин НЕ установлен):**
Когда я прошу «сделай схему drawio» и у меня НЕ установлен `Agents365-ai/drawio-skill`, я (разработчик документации) хочу получить от `gramax:drawio` чёткую инструкцию по установке внешнего плагина с точными командами, чтобы не гадать, почему ничего не происходит и где найти нужный инструмент.

**Story 4 — неявный запрос «нарисуй диаграмму»:**
Когда я прошу «визуализируй процесс» или «нарисуй диаграмму» без указания движка, я (автор документации, не знакомый с разницей mermaid/drawio) хочу получить уточняющий вопрос: «mermaid (inline, без preview, без файла) или drawio (через внешний плагин, с `.svg`-файлом)?», чтобы осознанно выбрать инструмент под свой кейс.

## Описание

В версии 2.0.0 плагин содержит `gramax:mermaid` для inline-диаграмм и делегирует drawio на внешний `Agents365-ai/drawio-skill`. Оба skill'а упоминают движок в description, но нет явного skill'а `gramax:drawio`, который был бы точкой входа для drawio-запросов внутри плагина.

При неявных запросах («нарисуй диаграмму», «визуализируй процесс») ни mermaid, ни drawio не имеют чёткого приоритета — Claude может активировать любой из них или внешний плагин непредсказуемо. Пользователь не получает объяснения разницы между инструментами.

Директива пользователя (2026-05-11): «используем только gramax:mermaid и drawio, уточни описание скилов и я хочу, чтобы ты добавил заглушку для drawio — gramax:drawio. Пользователь либо явно указывает инструмент, либо навык уточняет какой».

Параллельно — удалить `plugins/claude-mermaid/` (vendored submodule), так как он создаёт конфликт триггеров с `gramax:mermaid` (оба активируются на «нарисуй flowchart/sequence/...»). Это breaking change для пользователей, которые опирались на MCP-preview из `claude-mermaid`.

Версия плагина поднимается до **3.0.0** (major: удаление vendored плагина + добавление нового public skill).

## Функциональные требования

- **FR-001:** skill `plugins/gramax/skills/drawio/SKILL.md` существует и объявлен в `plugins/gramax/.claude-plugin/plugin.json`.
- **FR-002:** description skill'а `gramax:drawio` триггерится на «нарисуй drawio», «сделай схему drawio», «диаграмма drawio», «drawio-схема» и НЕ триггерится на «нарисуй mermaid» или «нарисуй диаграмму» без указания движка.
- **FR-003:** description skill'а `gramax:mermaid` триггерится на «нарисуй mermaid», «mermaid-диаграмма», «flowchart mermaid», «sequence mermaid» и НЕ триггерится на «нарисуй drawio» или «нарисуй диаграмму» без указания движка.
- **FR-004:** при явном drawio-запросе skill `gramax:drawio` информирует пользователя о необходимости внешнего плагина `Agents365-ai/drawio-skill` и предоставляет команды установки.
- **FR-005:** при явном drawio-запросе skill `gramax:drawio` описывает двухшаговый Gramax-workflow: drawio-skill создаёт `.svg` → writer-skill помогает вставить тег `[drawio:...]`.
- **FR-006:** при неоднозначном запросе (нет ключевого слова движка) один из skill'ов (см. открытый вопрос OQ-001) задаёт уточняющий вопрос: «mermaid (inline DSL, без файла, без preview) или drawio (через внешний плагин, создаёт `.svg`-файл)?».
- **FR-007:** description `gramax:mermaid` явно указывает «для drawio → `gramax:drawio`», убирает упоминания `Agents365-ai/mermaid-skill` как конфликтующего инструмента (теперь разграничение идёт через собственный drawio skill).
- **FR-008:** `plugins/claude-mermaid/` удалён как submodule (deinit + entry в `.claude-plugin/marketplace.json` удалён или обновлён).
- **FR-009:** `plugins/gramax/.claude-plugin/plugin.json` содержит `"version": "3.0.0"`.
- **FR-010:** `.claude-plugin/marketplace.json` не содержит entry для `claude-mermaid` (или помечает его как удалённый).
- **FR-011:** `plugins/gramax/CHANGELOG.md` содержит секцию `## 3.0.0` с подразделами Added, Removed, Changed, Migration.

## Нефункциональные требования

- **NFR-001:** `plugins/gramax/skills/drawio/SKILL.md` — не более 2000 токенов (≈ 1500 слов). Skill является заглушкой-делегатором, а не полноценной реализацией.
- **NFR-002:** Backward-compat для явных mermaid-запросов — пользователи v2.x с явным «mermaid» в запросе продолжают получать `gramax:mermaid` без изменений в поведении.
- **NFR-003:** Breaking-compat: пользователи v2.x, опиравшиеся на `claude-mermaid` MCP-preview (`mermaid_preview`, `mermaid_save`), теряют эту функциональность. Это допустимо по директиве пользователя — фиксируется в migration notes.
- **NFR-004:** `bash scripts/check.sh --fast` проходит без ошибок после всех изменений.
- **NFR-005:** Оба skill'а (mermaid, drawio) работают на macOS и Linux (bash 3.2+). Внешние зависимости — только у drawio-skill (внешний плагин), не у mermaid.
- **NFR-006:** Описание (description) обоих skill'ов сформулировано так, что Claude не активирует «не тот» skill при явном указании движка в запросе — это минимизируется через keywords и явные «не для» формулировки (полное исключение невозможно — открытый вопрос OQ-006).

## UX / интерфейс

**Явный mermaid:** пользователь пишет «нарисуй mermaid ...» → `gramax:mermaid` активируется сразу → генерирует DSL → вставляет в md. Без уточняющих вопросов.

**Явный drawio:** пользователь пишет «нарисуй drawio ...» → `gramax:drawio` активируется → выводит:
```
Для drawio-диаграмм используется внешний плагин.

Если ещё не установлен:
  /plugin marketplace add Agents365-ai/365-skills
  /plugin install drawio

Двухшаговый workflow в Gramax:
  Шаг 1: вызови drawio-skill — он создаст .drawio + .svg в рабочей директории.
  Шаг 2: вставь тег в md-страницу (writer-skill подскажет формат):
    [drawio:./diagram.svg:Описание:800px:600px]
```

**Неявный запрос:** пользователь пишет «нарисуй диаграмму / визуализируй процесс» → активировавшийся skill задаёт уточняющий вопрос:
```
Какой движок использовать?
- mermaid — inline DSL, без файла, без preview (рендер — Gramax-фронтенд)
- drawio — через внешний плагин Agents365-ai/drawio-skill, создаёт .svg-файл
```

## Acceptance Criteria

- [ ] **AC-001:** файл `plugins/gramax/skills/drawio/SKILL.md` существует:
  `test -f plugins/gramax/skills/drawio/SKILL.md && echo PASS`

- [ ] **AC-002:** `plugins/gramax/.claude-plugin/plugin.json` содержит skill `drawio` в секции skills:
  `python3 -c "import json; d=json.load(open('plugins/gramax/.claude-plugin/plugin.json')); skills=[s['name'] for s in d.get('skills',[])] if isinstance(d.get('skills',[]),list) else list(d.get('skills',{}).keys()); assert 'drawio' in skills, skills; print('PASS')"`

- [ ] **AC-003:** description `gramax:drawio` содержит ключевые слова, связанные с «drawio»:
  `grep -i 'drawio' plugins/gramax/skills/drawio/SKILL.md | grep -i 'description\|триггер\|нарисуй' | wc -l | grep -qv '^0$' && echo PASS`

- [ ] **AC-004:** `gramax:drawio` SKILL.md содержит команду установки внешнего плагина:
  `grep -c 'Agents365-ai/365-skills\|plugin install drawio' plugins/gramax/skills/drawio/SKILL.md | grep -qv '^0$' && echo PASS`

- [ ] **AC-005:** `gramax:drawio` SKILL.md содержит описание двухшагового workflow с тегом `[drawio:`:
  `grep -c '\[drawio:' plugins/gramax/skills/drawio/SKILL.md | grep -qv '^0$' && echo PASS`

- [ ] **AC-006:** `gramax:drawio` SKILL.md содержит уточняющий вопрос или упоминание mermaid как альтернативы:
  `grep -ic 'mermaid' plugins/gramax/skills/drawio/SKILL.md | grep -qv '^0$' && echo PASS`

- [ ] **AC-007:** `gramax:mermaid` SKILL.md description не упоминает `Agents365-ai/mermaid-skill` как предупреждение о конфликте (теперь разграничение через `gramax:drawio`):
  `grep -c 'mermaid-skill\|365-skills.*mermaid\|mermaid.*365-skills' plugins/gramax/skills/mermaid/SKILL.md | grep -q '^0$' && echo PASS`

- [ ] **AC-008:** `gramax:mermaid` SKILL.md содержит явную ссылку «для drawio → `gramax:drawio`»:
  `grep -c 'gramax:drawio\|gramax.*drawio' plugins/gramax/skills/mermaid/SKILL.md | grep -qv '^0$' && echo PASS`

- [ ] **AC-009:** submodule `plugins/claude-mermaid/` не зарегистрирован в `.gitmodules`:
  `test ! -f .gitmodules && echo PASS || grep -c 'claude-mermaid' .gitmodules | grep -q '^0$' && echo PASS`

- [ ] **AC-010:** каталог `plugins/claude-mermaid/` отсутствует или пуст:
  `test ! -d plugins/claude-mermaid || find plugins/claude-mermaid -mindepth 1 | wc -l | grep -q '^0$' && echo PASS`

- [ ] **AC-011:** `.claude-plugin/marketplace.json` не содержит активного entry для `claude-mermaid`:
  `python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); names=[p.get('name','') for p in d.get('plugins',[])]; assert 'claude-mermaid' not in names, names; print('PASS')"`

- [ ] **AC-012:** `plugins/gramax/.claude-plugin/plugin.json` содержит `"version": "3.0.0"`:
  `python3 -c "import json; d=json.load(open('plugins/gramax/.claude-plugin/plugin.json')); assert d['version']=='3.0.0', d['version']; print('PASS')"`

- [ ] **AC-013:** `plugins/gramax/CHANGELOG.md` содержит секцию `## 3.0.0` и подраздел `### Migration`:
  `grep -c '## 3.0.0' plugins/gramax/CHANGELOG.md | grep -qv '^0$' && grep -c '### Migration' plugins/gramax/CHANGELOG.md | grep -qv '^0$' && echo PASS`

- [ ] **AC-014:** `bash scripts/check.sh --fast` завершается с exit code 0:
  `bash scripts/check.sh --fast && echo PASS`

- [ ] **AC-015:** `plugins/gramax/skills/drawio/SKILL.md` не превышает 2000 строк (прокси-проверка объёма):
  `wc -l < plugins/gramax/skills/drawio/SKILL.md | awk '{exit ($1 > 200)}' && echo PASS`

## Открытые вопросы для SA (ADR-0009)

**OQ-001: Где живёт логика «уточняющего вопроса» при неявном запросе?**
Три варианта: (a) в обоих skill'ах (mermaid и drawio) — оба описывают неоднозначный кейс в description, Claude выбирает один; (b) третий skill-диспетчер `gramax:diagram` — но ADR-0004 явно отверг router-skill как паттерн; (c) только в `gramax:drawio` (на том основании, что mermaid — умолчание для inline, drawio — требует внешней установки). SA должен выбрать и обосновать, не нарушая ADR-0004.

**OQ-002: Процедура удаления `plugins/claude-mermaid/` как git submodule.**
Правильная последовательность: `git submodule deinit -f plugins/claude-mermaid`, `git rm plugins/claude-mermaid`, удаление строки из `.gitmodules`, удаление секции из `.git/config`, `rm -rf .git/modules/plugins/claude-mermaid`. SA должен зафиксировать точный порядок в ADR/брифе Dev, чтобы не сломать git state worktree.

**OQ-003: Версия — 3.0.0 обязательна?**
Удаление vendored плагина (`claude-mermaid`) из marketplace — это breaking change для пользователей, установивших marketplace и ожидающих claude-mermaid в каталоге. ADR-0006 предписывает major bump при удалении компонента marketplace. SA подтверждает 3.0.0 или обосновывает исключение.

**OQ-004: Что делать с MCP-сервером `claude-mermaid` в `.claude/settings.json`?**
Если пользователи добавили `mermaid_preview`/`mermaid_save` в свой локальный `mcpServers` через инструкцию из README, удаление submodule не удалит MCP-конфигурацию у них. SA решает: нужно ли в migration notes описывать явный шаг удаления MCP из `settings.json`, и если да — как сформулировать инструкцию без доступа к файлам пользователя.

**OQ-005: Формулировки description для минимизации ложных триггеров.**
`gramax:mermaid` description сейчас содержит «flowchart/sequence/gantt/...» — те же слова использует drawio-skill из `Agents365-ai/365-skills`. После добавления `gramax:drawio` появляется риск, что неявный запрос «нарисуй flowchart» активирует drawio вместо mermaid. SA должен предложить конкретные формулировки (keyword-strategy), которые разграничивают движки на уровне description, и зафиксировать их как контракт в ADR-0009.

**OQ-006: Как skill определяет «явный engine» vs «неявный» — keyword-match или интуиция Claude?**
При keyword-match («drawio», «mermaid» в запросе) выбор детерминирован. При неявном запросе («нарисуй диаграмму») — недетерминирован: Claude читает description и выбирает. SA должен: (a) зафиксировать, что явный keyword — единственный гарантированный способ детерминированного роутинга; (b) описать ожидаемое поведение при неявном запросе (уточняющий вопрос vs умолчание mermaid); (c) указать, является ли поведение при неявном запросе частью контракта или best-effort.

**OQ-007: Нужен ли skill-файл `SKILL.md` или достаточно `plugin.json` declaration?**
SA решает: является ли `gramax:drawio` полноценным SKILL.md с инструкциями (как `gramax:mermaid`) или достаточно минимальной декларации в `plugin.json` с description, а логика уточняющего вопроса встроена в mermaid-skill. Это влияет на то, что именно пишет Dev.

## Out of scope

- Авто-detect движка по семантике запроса без явного указания пользователя (Phase 4 / future).
- Slash-команда `/gramax:diagram <engine>` — отвергнута ADR-0004.
- Восстановление preview-функциональности `claude-mermaid` (`mermaid_preview`, `mermaid_save`) — теряется осознанно по директиве пользователя.
- Изменения в `plugins/gramax/skills/writer/` — drawio-workflow там уже описан по ADR-0008.
- Адаптер-обёртка над внешним `Agents365-ai/drawio-skill` с автовставкой тега — сложность не оправдана на данном этапе.
- Поддержка `Agents365-ai/mermaid-skill` как альтернативы `gramax:mermaid`.

## Зависимости

- **ADR-0008** (Accepted, 2026-05-11) — установил делегирование drawio на внешний плагин и структуру двухшагового workflow. Данная фича расширяет этот паттерн явным skill'ом.
- **ADR-0004** (Superseded by ADR-0008) — отверг router-skill. OQ-001 требует reconciliation с этим решением.
- **ADR-0006** — semver-policy, определяет необходимость major bump.
- **Будущий ADR-0009** — должен ответить на OQ-001—OQ-007 и задокументировать решения для Dev.

## Migration impact для пользователей v2.x

| Пользователь | Было | Станет | Действие |
|---|---|---|---|
| Использует `gramax:mermaid` с явным «mermaid» | Работает | Работает без изменений | Ничего |
| Использует `claude-mermaid` MCP-preview (`mermaid_preview`) | Работает | Skill и MCP недоступны | Удалить MCP из `settings.json`; использовать `gramax:mermaid` (без preview) |
| Хочет создать drawio-диаграмму | Нет явного skill'а | `gramax:drawio` подсказывает установку | Установить `Agents365-ai/drawio-skill` |
| Неявный запрос «нарисуй диаграмму» | Непредсказуемо | Уточняющий вопрос | Указывать движок явно или отвечать на вопрос |

## Бриф для SA

**Spec:** `docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md`

**Спроектировать (ADR-0009):**
- Ответить на OQ-001—OQ-007 (критичны OQ-001, OQ-005, OQ-006).
- Зафиксировать точный формат `plugins/gramax/skills/drawio/SKILL.md`: полноценный skill vs минимальная заглушка.
- Определить процедуру `git submodule deinit` для `claude-mermaid` (OQ-002).
- Подтвердить semver 3.0.0 (OQ-003).
- Написать конкретные keyword-формулировки для description обоих skill'ов (OQ-005).

**Бизнес-правила:**
- `gramax:mermaid` не меняет своей функциональности — только обновляется description.
- `gramax:drawio` — заглушка-делегатор, не реализует генерацию самостоятельно.
- Двухшаговый Gramax-workflow (drawio-skill → writer-skill) — канонический, зафиксирован ADR-0008.
- `bash scripts/check.sh --fast` должен быть зелёным (AC-014).

**Acceptance Criteria для проверки архитектуры:** AC-001, AC-002, AC-009, AC-010, AC-011, AC-012, AC-014.
