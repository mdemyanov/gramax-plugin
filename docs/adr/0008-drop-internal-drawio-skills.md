# ADR-0008: Удаление внутренних drawio-skills и делегирование внешнему плагину

**Status:** Accepted
**Date:** 2026-05-11
**Plugin:** gramax / marketplace

## Context

Плагин gramax@1.4.0 содержит два skill'а для работы с drawio-диаграммами (`diagram-on-demand`, `diagrams`) и пять вспомогательных скриптов (`drawio_convert.py`, `find_doc_root.sh`, `save_diagram.sh`, `insert_diagram_ref.sh`, `validate_diagram_type.sh`). Архитектурные решения ADR-0001, ADR-0004, ADR-0005 зафиксировали этот pipeline как самодостаточный MVP.

Исследование RES-001 (2026-05-11) показало, что сторонний плагин `Agents365-ai/drawio-skill` (v1.5.2, MIT) покрывает основной сценарий — генерацию `.drawio` + экспорт в SVG/PNG — и поддерживается отдельной командой. Функциональность не идентична: внешний плагин не знает о `.doc-root.yaml`, не вставляет ссылку в md, не учитывает Gramax-теги. Это осознанный trade-off: сокращение поверхности поддержки взамен на ручной шаг вставки тега пользователем.

Spec `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md` формулирует семь открытых вопросов для SA. Данный ADR отвечает на все семь и является единственной точкой архитектурных решений для фазы удаления.

## Решение 1 — Major bump 2.0.0 (а не 1.5.0)

**Решение:** версия плагина поднимается до **2.0.0**; `marketplace.json metadata.version` поднимается до **2.0.0**.

**Обоснование по ADR-0006 (semver-strategy):**

ADR-0006 зафиксировал семантику в контексте marketplace:
- **Patch (x.x.N)** — bug fix, исправление описания без изменения функциональности.
- **Minor (x.N.0)** — additive change: новый skill, новая команда внутри существующего плагина.
- **Major (N.0.0)** — breaking change: удаление skill, несовместимое изменение, смена структуры `marketplace.json`.

Удаление skill'ов `diagrams` и `diagram-on-demand` является breaking change по трём критериям одновременно:

1. **Публичные skill-имена удаляются.** Пользователи, чьи workflow опираются на `/gramax:diagrams` или `/gramax:diagram-on-demand` (явные вызовы), получат ошибку «skill not found». Это прямое нарушение обратной совместимости.
2. **Публичный скрипт удаляется.** `drawio_convert.py` был доступен через `${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py`. Пользователи, встроившие его в собственные пайплайны, потеряют инструмент. ADR-0006 относит «удаление компонента, объявленного как часть контракта плагина» к major.
3. **Workflow изменяется несовместимо.** Drawio-workflow из одношагового (один вызов skill'а) становится двухшаговым с внешней зависимостью. Пользователи должны установить сторонний плагин и принять ручной шаг вставки тега.

Minor bump 1.5.0 неприменим: ADR-0006 явно ограничивает minor случаями additive change. Удаление двух skills и пяти скриптов не является additive.

**Синхронный bump обоих версионных полей обязателен** (конвенция из ADR-0006, «Отрицательные / trade-offs»): `plugins/gramax/.claude-plugin/plugin.json` → `2.0.0`; `.claude-plugin/marketplace.json` → `metadata.version: "2.0.0"`.

## Решение 2 — Полное удаление drawio_convert.py без deprecated-периода

**Решение:** `drawio_convert.py` удаляется полностью. Переход в `scripts/deprecated/` не выполняется.

**Обоснование:**

`drawio_convert.py` имеет два типа потребителей:
1. **Внутренние** — `skills/diagram-on-demand/` и `skills/diagrams/`. Оба skill'а удаляются в рамках этого же изменения. Внутренний потребитель исчезает вместе со скриптом.
2. **Внешние** — пользователи, встроившие скрипт в собственные пайплайны через `${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py`.

Аргументы за полное удаление (без deprecated-периода):

- **Сигнал: major bump.** Именно для этого и существует major версия. Пользователи, следящие за semver, знают, что 2.0.0 = breaking change. Deprecated-директория создаёт ложное ощущение поддержки без реальных гарантий.
- **Deprecated-директория без теста — мусор.** Скрипт в `scripts/deprecated/` не будет покрыт smoke-тестами (мы тестируем только актуальный код). Со временем он устареет, накопит битые ссылки и создаст путаницу для новых контрибьюторов.
- **Предупреждение на stderr не меняет ситуацию.** Пользователь всё равно должен переделать пайплайн. Предупреждение лишь откладывает осознание этого факта.
- **Migration note в CHANGELOG достаточен.** Пользователи, полагавшиеся на скрипт, получат явную инструкцию в `CHANGELOG.md ## 2.0.0 ### Migration`: «скрипт удалён, его функциональность (конвертация `.drawio` → SVG с embedded XML) не воспроизведена во внешнем плагине; пользователям, зависевшим от скрипта в собственных пайплайнах, рекомендуется сохранить копию из тега v1.4.0 или перейти на CLI draw.io desktop».

**Риск принят осознанно:** сужение совместимости для внешних потребителей скрипта — это именно то, что фиксирует major bump.

## Решение 3 — Политика статусов ADR-0001—0007

**Решение:** четыре ADR помечаются как Superseded, два — как Historical, один остаётся Active.

Конкретная разбивка:

| ADR | Текущий статус | Новый статус | Обоснование |
|-----|----------------|--------------|-------------|
| 0001 (no split) | Accepted | **Superseded by ADR-0008** | Решение «держать skills внутри gramax» отменяется: skills удаляются |
| 0002 (drawio MCP backend) | Accepted | **Historical (Informational)** | Описывает выбор MCP-бэкенда для удалённой функциональности; остаётся как контекст для понимания истории, не как действующий контракт |
| 0003 (vendoring strategy) | Accepted | **Historical (Informational)** | Описывает vendoring-стратегию для drawio MCP; действующего контракта не создаёт после удаления skills |
| 0004 (router & engine selection) | Accepted | **Superseded by ADR-0008** | Архитектура router'а внутри `diagram-on-demand` теряет смысл при удалении skill'а |
| 0005 (save flow API contract) | Accepted | **Superseded by ADR-0008** | Контракт drawio_convert.py / find_doc_root.sh / slugify.py как pipeline API полностью упраздняется |
| 0006 (semver strategy) | Accepted | **Active** | Semver-стратегия для marketplace.json продолжает действовать; ADR-0008 применяет её, а не отменяет |
| 0007 (out-of-scope Phase 2) | Accepted | **Superseded by ADR-0008** | Phase 2 для drawio pipeline теряет релевантность; альтернативы (external plugin) реализуются иначе |

**Процедура:** согласно правилу ADR-репозитория («не изменяй старый ADR») — Dev не трогает frontmatter ADR-0001—0007. Данный ADR фиксирует решение; фактическое обновление статусов в старых файлах выполняется Dev как отдельная задача с явным sign-off PM.

**Обоснование разделения Superseded vs Historical:**

- **Superseded** — когда ADR принимал решение, которое данный ADR явно отменяет (skill-структура, API-контракт, engine selection).
- **Historical (Informational)** — когда ADR описывает технический исследовательский выбор (какой MCP лучше, как его поставлять), который был валиден в контексте старой архитектуры, не противоречит новой, но более не применим. Эти ADR ценны как документация пути, но не создают действующих контрактов.

ADR-0006 остаётся **Active** специально: это не описание удалённой функциональности, а политика семантического версионирования для всего репозитория. Данный ADR-0008 прямо использует ADR-0006 в Решении 1.

## Решение 4 — Целевая структура writer/references/drawio.md

**Решение:** файл `plugins/gramax/skills/writer/references/drawio.md` полностью реструктурируется согласно следующей схеме.

**Удаляются разделы:**
- «Готовый инструмент» (блок с `drawio_convert.py` и deflate-сжатием).
- «Конвертация .drawio → SVG (обязательно)» с командой `python3 ... drawio_convert.py`.
- Все ссылки на ручную сборку mxfile XML, slugify.py, find_doc_root.sh, save_diagram.sh.

**Целевая структура после изменений:**

```
## Создание drawio-диаграммы в Gramax

### Prerequisites
- draw.io desktop установлен и добавлен в PATH
  - macOS: `brew install --cask drawio`
  - Windows: инсталлятор с github.com/jgraph/drawio-desktop/releases (добавить в PATH)
  - Linux: `.deb`/`.rpm` (не snap); headless-серверы: дополнительно `xvfb`
- Python 3 (для `repair_png.py` в составе drawio-skill)
- Внешний drawio-плагин установлен:
  `/plugin marketplace add Agents365-ai/365-skills`
  `/plugin install drawio`

### Двухшаговый workflow

**Шаг 1.** Вызови drawio-skill — он сгенерирует `.drawio` + SVG-экспорт:
Описание диаграммы на натуральном языке → drawio-skill создаёт файлы в CWD.

**Шаг 2.** Вставь тег вручную в нужную md-страницу.
Writer-skill подскажет правильный формат (см. раздел «Gramax-теги» ниже).

Важно: drawio-skill не знает о `.doc-root.yaml` и не вставляет ссылку автоматически.
Именование файлов и путь — на ответственности пользователя.

### Gramax-теги для drawio

Формат вставки зависит от `syntax:` в ближайшем `.doc-root.yaml`:

**syntax: Markdown (по умолчанию):**
```
[drawio:./diagram.svg:Описание диаграммы:800px:600px]
```

**syntax: XML:**
```xml
<Image src="./diagram.svg" alt="Описание диаграммы" />
```

Размеры (WxH) опциональны. Файл `.svg` должен лежать рядом с `.md`-страницей или
по относительному пути от неё.
```

**NFR-005 выполняется:** раздел Gramax-тегов (синтаксис `[drawio:...]` и `<Image src="..."/>`) сохраняется и не удаляется — это часть Gramax-контракта, не зависящая от наличия `drawio_convert.py`.

## Решение 5 — Уточнение mermaid SKILL.md description

**Решение:** В поле `description` frontmatter `plugins/gramax/skills/mermaid/SKILL.md` добавляется явное ограничение области применения и указание на альтернативу для drawio.

**Текущее description (приблизительно):** описывает mermaid как инструмент для flowchart/sequence/gantt/etc — те же слова, что использует drawio-skill из `Agents365-ai/365-skills`.

**Целевое дополнение (добавить в конец description или как отдельное поле `scope`):**

> Только для диаграмм в синтаксисе Mermaid DSL (flowchart, sequence, gantt, classDiagram, ER и др.). Для drawio-диаграмм — используй внешний плагин drawio из marketplace Agents365-ai/365-skills, не этот skill.

**Дополнительно:** в секцию «Не для» (или аналогичный блок в SKILL.md) добавить явный пункт:
> - drawio-диаграммы (`.drawio` файлы) — для них используй Agents365-ai/drawio-skill

Это снижает риск того, что Claude активирует mermaid-skill при запросе «нарисуй drawio-диаграмму».

## Решение 6 — Политика параллельной установки 365-skills/mermaid

**Решение:** пользователям, использующим `gramax:mermaid`, **не рекомендуется** устанавливать `Agents365-ai/mermaid-skill` из 365-skills параллельно.

**Обоснование:** оба skill'а используют семантические триггеры через `description`. Формулировки «flowchart», «sequence diagram», «gantt» присутствуют в обоих. Claude не имеет детерминированного механизма выбора между двумя конкурирующими skill-описаниями — результат недетерминирован и зависит от контекста разговора.

**Оформление:** явный `WARNING` добавляется в `plugins/gramax/README.md` в раздел Prerequisites (или в отдельный раздел «Конфликты плагинов»):

```
> **Warning:** Не устанавливайте `Agents365-ai/mermaid-skill` из 365-skills одновременно
> с `gramax:mermaid`. Оба skill'а описывают одинаковые триггеры (flowchart, sequence,
> gantt и др.) — Claude может выбрать не тот, поведение становится недетерминированным.
> Для drawio устанавливайте только `drawio` из 365-skills (не `mermaid`).
```

**Рекомендуемый subset из 365-skills для пользователей gramax:** только `/plugin install drawio`. Mermaid — из gramax (уже установлен как часть плагина).

## Решение 7 — Изменение корневого marketplace.json

**Решение:** корневой `.claude-plugin/marketplace.json` обновляется по трём полям.

**Изменяемые поля:**

| Поле | Старое значение | Новое значение |
|------|----------------|----------------|
| `metadata.version` | `"1.2.0"` | `"2.0.0"` |
| `metadata.description` | `"Claude Code marketplace для Gramax-документации: writer, comments, diagrams, diagram-on-demand, mermaid, review-agent. С опциональным claude-mermaid (vendored)."` | `"Claude Code marketplace для Gramax-документации: writer, comments, mermaid, review-agent. Drawio — через внешний плагин Agents365-ai/drawio-skill."` |
| `plugins[gramax].description` | `"Документация Gramax: writer, comments-read, comments-write, diagrams (drawio/mermaid), diagram-on-demand, mermaid, review-agent."` | `"Документация Gramax: writer, comments-read, comments-write, mermaid, review-agent. Drawio-диаграммы — через Agents365-ai/drawio-skill (внешний)."` |

**Обоснование bump до 2.0.0 в marketplace.json:** ADR-0006 фиксирует, что Major bump в `marketplace.json` происходит при breaking change. Удаление двух skill'ов из публичного плагина `gramax` является breaking change (Решение 1). `marketplace.json` и `plugin.json` версионируются синхронно (конвенция ADR-0006).

**Что НЕ меняется:** структура JSON (поля `name`, `owner`, `plugins`-массив, `source`-пути), количество plugins-entry (два: `gramax` + `claude-mermaid`), статус `claude-mermaid` entry.

**PM sign-off требуется:** согласно CLAUDE.md («НЕ менять `.claude-plugin/marketplace.json` без ADR»), данный ADR является разрешающим документом. Дополнительного PM sign-off не требуется, поскольку изменение документировано здесь. Однако синхронизация обоих файлов (marketplace.json + plugin.json) обязательна в одном коммите — расхождение версий недопустимо (ADR-0006, «Отрицательные / trade-offs», mitigation).

## Consequences

**Положительные:**
- Поверхность поддержки плагина gramax сокращается: 2 skill'а + 5 скриптов удаляются.
- `drawio_convert.py` — самый сложный компонент с зависимостями от Python deflate + SVG-рендера — выходит из зоны ответственности команды.
- Пользователи получают более поддерживаемый внешний drawio-pipeline (`Agents365-ai/drawio-skill`, MIT).
- Mermaid-skill сохраняется без изменений в функциональности.
- Уточнение description mermaid-skill снижает конфликт триггеров с внешними диаграммными плагинами.

**Отрицательные / trade-offs:**
- Breaking change для пользователей версии 1.x: skill'ы исчезают, workflow усложняется (ручной шаг вставки тега).
- Onboarding стал тяжелее: пользователь должен установить draw.io desktop + Python 3 + два шага `marketplace add` / `plugin install`.
- Drawio-workflow теряет автоматическую вставку тега в md и знание о `.doc-root.yaml`.
- Пользователи, встроившие `drawio_convert.py` в собственные пайплайны, должны адаптироваться.

**Mitigations:**
- CHANGELOG.md § 2.0.0 содержит полный Migration guide с пошаговой инструкцией.
- README содержит блок Prerequisites с платформенными деталями (macOS/Windows/Linux headless).
- Тег v1.4.0 остаётся в git-истории: пользователи могут извлечь `drawio_convert.py` из него самостоятельно.
- Warning в README предупреждает о конфликте triггеров с 365-skills/mermaid.

## Risks (найденные при проектировании)

**RISK-001: Python 3 на Windows.** Внешний `drawio-skill` использует `repair_png.py` — Python 3 обязателен. На Windows Python 3 не поставляется вместе с системой. README должен явно описывать установку (`python.org`); отсутствие Python 3 → `repair_png.py` упадёт; drawio-skill будет частично неработоспособен. **Mitigation:** добавить в Prerequisites README явную инструкцию для Windows с предупреждением об обязательности Python 3.

**RISK-002: Linux snap-версия draw.io.** Snap AppArmor-sandbox блокирует keyring, вызывая краш draw.io CLI. Headless-серверы дополнительно требуют `xvfb`. **Mitigation:** зафиксировать в Prerequisites README явно: «не snap», рекомендовать `.deb`/`.rpm`; для headless — `sudo apt install xvfb` + `xvfb-run`.

**RISK-003: Конфликт триггеров mermaid vs drawio-skill.** При установленных одновременно `gramax:mermaid` и `Agents365-ai/mermaid-skill` поведение Claude недетерминировано. **Mitigation:** Решение 5 уточняет description; Решение 6 добавляет WARNING в README. Полного исключения конфликта при параллельной установке достигнуть невозможно — только документирование.

**RISK-004: Versioning drift.** Если `plugin.json` и `marketplace.json` будут обновлены в разных коммитах, версии разойдутся. **Mitigation:** pm-review checklist проверяет синхронность; Dev обновляет оба файла в одном коммите (зафиксировано в брифе).

**RISK-005: drawio-skill не вставляет Gramax-теги.** Пользователи, привыкшие к автоматической вставке `[drawio:...]`, могут не знать правильного синтаксиса. **Mitigation:** Решение 4 явно описывает синтаксис тегов в `writer/references/drawio.md`; writer-skill будет подсказывать формат при запросе.

## Alternatives Considered

- **Minor bump 1.5.0 с deprecation-предупреждениями.** Отклонено: удаление публичных skill'ов является breaking change по определению ADR-0006; minor-bump создаст путаницу у пользователей, ожидающих семантической совместимости.
- **Сохранение `drawio_convert.py` в `scripts/deprecated/`.** Отклонено: скрипт без тестового покрытия устареет, создаст ложное ощущение поддержки; migration note в CHANGELOG достаточен.
- **Сохранение stub-skills с сообщением «использует внешний плагин».** Отклонено: stub создаёт иллюзию функциональности; пользователь должен явно знать, что skill удалён и нужен внешний плагин.
- **Все ADR 0001-0007 помечаются Superseded.** Отклонено: ADR-0002/0003 описывают исследовательский выбор MCP-бэкенда, который не создавал действующих контрактов; их полезнее сохранить как исторический контекст, чем объявить недействительными.

## Бриф для Dev

**Spec:** `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md`
**ADR:** `docs/adr/0008-drop-internal-drawio-skills.md`

**Реализовать в указанном порядке:**

1. **Удаление skill'ов и скриптов** (AC-001—AC-004, AC-016):
   - `plugins/gramax/skills/diagram-on-demand/` — удалить каталог целиком
   - `plugins/gramax/skills/diagrams/` — удалить каталог целиком
   - `plugins/gramax/scripts/find_doc_root.sh` — удалить
   - `plugins/gramax/scripts/save_diagram.sh` — удалить
   - `plugins/gramax/scripts/insert_diagram_ref.sh` — удалить
   - `plugins/gramax/scripts/validate_diagram_type.sh` — удалить
   - `plugins/gramax/scripts/drawio_convert.py` — удалить

2. **Обновление writer-skill** (AC-005—AC-008):
   - `plugins/gramax/skills/writer/SKILL.md` — убрать команды с `drawio_convert.py`, описать двухшаговый workflow
   - `plugins/gramax/skills/writer/references/drawio.md` — реструктурировать по схеме из Решения 4
   - `plugins/gramax/skills/writer/references/staging.md` — убрать блок с `drawio_convert.py`

3. **Обновление mermaid SKILL.md** (AC-014):
   - `plugins/gramax/skills/mermaid/SKILL.md` — уточнить description по Решению 5

4. **Обновление README** (AC-009, AC-010):
   - `plugins/gramax/README.md` — убрать `diagram-on-demand`/`diagrams`, добавить Prerequisites (Решение 4), добавить WARNING по Решению 6

5. **Bump версий и manifests** (AC-011, AC-012) — в одном коммите:
   - `plugins/gramax/.claude-plugin/plugin.json` → `"version": "2.0.0"`, обновить description, keywords
   - `.claude-plugin/marketplace.json` → `metadata.version: "2.0.0"`, обновить descriptions (Решение 7)

6. **CHANGELOG** (AC-013):
   - `plugins/gramax/CHANGELOG.md` — добавить секцию `## 2.0.0` с Removed / Changed / Migration

7. **Проверка** (AC-015, AC-016):
   - `bash scripts/check.sh --fast` — зелёный

**Acceptance Criteria из spec:** AC-001—AC-016 (все проверяемы shell-командами, см. spec §Acceptance Criteria).

**Порядок:** failing stubs QA → удаление (шаг 1) → обновление content (шаги 2-4) → manifests (шаг 5) → CHANGELOG (шаг 6) → smoke зелёный (шаг 7).

## Контракт с QA-author

**AC (полный список из spec):**
- AC-001: каталог `diagram-on-demand/` отсутствует
- AC-002: каталог `diagrams/` отсутствует
- AC-003: скрипты-сироты (4 штуки) отсутствуют
- AC-004: `drawio_convert.py` отсутствует
- AC-005: `writer/SKILL.md` не содержит `drawio_convert.py`
- AC-006: `writer/references/drawio.md` не содержит `drawio_convert.py`
- AC-007: `writer/references/staging.md` не содержит `drawio_convert.py`
- AC-008: `writer/references/drawio.md` содержит описание нового workflow (`Agents365-ai` или `drawio-skill`)
- AC-009: `README.md` содержит `marketplace add Agents365-ai/365-skills`
- AC-010: `README.md` не упоминает удалённые skills как доступные
- AC-011: `plugin.json` содержит `"version": "2.0.0"`
- AC-012: `marketplace.json` description не содержит `diagram-on-demand` или `diagrams`
- AC-013: `CHANGELOG.md` содержит `## 2.0.0` и `### Migration`
- AC-014: `mermaid/SKILL.md` description в frontmatter не содержит drawio как кейс применения
- AC-015: `bash scripts/check.sh --fast` exit code 0
- AC-016: ни один файл плагина не ссылается на удалённые скрипты

**Архитектурный контекст:**
- Скоуп удаления: `plugins/gramax/skills/diagram-on-demand/`, `plugins/gramax/skills/diagrams/`, 5 скриптов
- Скоуп обновления: writer (3 файла), mermaid (1 файл), README, plugin.json, marketplace.json, CHANGELOG
- External boundaries: файловая система (удаление файлов), JSON-манифесты (bump версий)
- Нет MCP, нет сетевых вызовов

**Edge cases / boundary conditions:**
- AC-016 охватывает не только `skills/`, но также `agents/`, `.claude-plugin/`, `README.md`, `CHANGELOG.md` — проверка должна быть широкой
- AC-012 требует парсинга JSON и проверки строки description в массиве `plugins`; простой `grep` может дать false negative если description многострочный
- AC-014 требует парсинга frontmatter YAML из SKILL.md; вложенное `description:` может содержать «drawio» в контексте «не для drawio» — проверка должна исключать ложные срабатывания
- `bash scripts/check.sh --fast` (AC-015) покрывает whitespace и JSON-валидность; после удаления файлов может упасть, если в check.sh есть hard-coded пути к удалённым скриптам — QA должен проверить сам `check.sh`

**Test-pyramid:**

| AC | Уровень | Обоснование |
|----|---------|-------------|
| AC-001, AC-002, AC-003, AC-004 | smoke | `test ! -d / test ! -f` — быстрые file-system проверки |
| AC-005, AC-006, AC-007 | smoke | `grep` на отсутствие строки — быстро, deterministic |
| AC-008 | smoke (позитивный) | `grep` на присутствие строки нового workflow |
| AC-009, AC-010 | smoke | `grep` на README |
| AC-011 | manifest-validation | JSON-парсинг `plugin.json`, поле `version` |
| AC-012 | manifest-validation | JSON-парсинг `marketplace.json`, `plugins[gramax].description` |
| AC-013 | smoke | `grep` на `CHANGELOG.md` |
| AC-014 | smoke (frontmatter) | парсинг frontmatter YAML из SKILL.md |
| AC-015 | smoke | `bash scripts/check.sh --fast` — интеграционный дымовой тест |
| AC-016 | integration | `grep -rn` по нескольким каталогам — широкий sweep |

## Связанные артефакты

- spec: `docs/superpowers/specs/2026-05-11-remove-diagram-skills.md`
- research: `docs/research/2026-05-11-drawio-skill-external.md`
- supersedes (в части архитектуры skills): ADR-0001, ADR-0004, ADR-0005, ADR-0007
- historical (не действующий контракт): ADR-0002, ADR-0003
- применяет (semver-policy): ADR-0006
- затрагивает: `plugins/gramax/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/gramax/skills/writer/`, `plugins/gramax/skills/mermaid/SKILL.md`, `plugins/gramax/README.md`, `plugins/gramax/CHANGELOG.md`
