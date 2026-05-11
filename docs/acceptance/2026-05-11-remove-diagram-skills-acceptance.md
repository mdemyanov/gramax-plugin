# Acceptance Report: remove-diagram-skills

Дата: 2026-05-11
BA: ba-agent (mode=acceptance)
Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
ADR: docs/adr/0008-drop-internal-drawio-skills.md
QA: docs/qa-reports/2026-05-11-remove-diagram-skills-qa-report.md

## Verdict

ACCEPTED WITH NOTES

Реализация функционально соответствует spec'у и ADR-0008 по всем 16 AC. QA-runner подтвердил 16/16 GREEN. Два замечания для Tech-writer (не блокеры) — тон и terminological consistency.

## JTBD coverage

- **Story 1 (сокращение поверхности плагина):** YES — `skills/diagram-on-demand/` и `skills/diagrams/` удалены (AC-001, AC-002). Пять скриптов удалены (AC-003, AC-004). В `plugin.json` keywords больше не содержат `drawio` как первичную функцию. Поверхность поддержки сокращена согласно замыслу.

- **Story 2 (drawio через внешний плагин):** YES — README содержит корректный блок Prerequisites с тремя командами в логичном порядке (`brew install`, `marketplace add`, `plugin install`), платформенные детали macOS/Windows/Linux включены (AC-009). WARNING про конфликт с `Agents365-ai/mermaid-skill` присутствует. `marketplace.json` и `plugin.json` не упоминают удалённые skills как доступные компоненты (AC-010, AC-011, AC-012). Двухшаговый workflow описан в `references/drawio.md` и `SKILL.md` (AC-008).

- **Story 3 (writer-skill описывает новый workflow):** YES — `writer/SKILL.md` содержит четырёхшаговый drawio-workflow без единого упоминания `drawio_convert.py` (AC-005). `references/drawio.md` полностью реструктурирован по схеме из ADR-0008 Решение 4: Prerequisites раздел чёткий, двухшаговый workflow читается, Gramax-теги `[drawio:...:WxH]` и `<Image src="..."/>` описаны (AC-006). `references/staging.md` обновлён без `drawio_convert.py` (AC-007).

## AC review (вручную)

| AC ID | Функциональная проверка (вручную) | Статус |
|-------|----------------------------------|--------|
| AC-001 | Каталог `skills/diagram-on-demand/` отсутствует — подтверждено структурой плагина | pass |
| AC-002 | Каталог `skills/diagrams/` отсутствует — подтверждено структурой плагина | pass |
| AC-003 | Четыре bash-скрипта-сироты не упоминаются ни в одном живом файле плагина | pass |
| AC-004 | `drawio_convert.py` не упоминается ни в одном живом файле плагина (AC-016 sweap подтверждён QA) | pass |
| AC-005 | `writer/SKILL.md` раздел «Diagrams (Draw.io)» описывает четырёхшаговый workflow через внешний плагин; `drawio_convert.py` отсутствует | pass |
| AC-006 | `writer/references/drawio.md` полностью реструктурирован: Prerequisites → Двухшаговый workflow → Gramax-теги → Troubleshooting; `drawio_convert.py` отсутствует | pass |
| AC-007 | `writer/references/staging.md` п. 2 ссылается на внешний drawio-skill без `drawio_convert.py`; чек-лист корректен | pass |
| AC-008 | `references/drawio.md` содержит `Agents365-ai/drawio-skill` и `/plugin marketplace add Agents365-ai/365-skills` | pass |
| AC-009 | README блок «Prerequisites» содержит все три команды: `brew install --cask drawio`, `marketplace add Agents365-ai/365-skills`, `plugin install drawio` | pass |
| AC-010 | README перечисляет только четыре актуальных skill (`writer`, `comments-read`, `comments-write`, `mermaid`); `diagram-on-demand` и `/gramax:diagrams` не упомянуты как доступные | pass |
| AC-011 | `plugin.json`: `version: "2.0.0"`, description без `diagrams`/`diagram-on-demand`, keywords: `["gramax", "documentation", "markdown", "comments", "mermaid", "review"]` — `drawio` отсутствует | pass |
| AC-012 | `marketplace.json`: `metadata.version: "2.0.0"`, `metadata.description` и `plugins[gramax].description` не содержат `diagram-on-demand` или `diagrams`; drawio упомянут только как делегированный внешнему плагину | pass |
| AC-013 | `CHANGELOG.md` содержит `## 2.0.0 — 2026-05-11` с подразделами Removed, Changed, Migration, ADR; дата проставлена | pass |
| AC-014 | `mermaid/SKILL.md` frontmatter description начинается с «Только для диаграмм в синтаксисе Mermaid DSL»; явно делегирует drawio внешнему плагину; drawio не фигурирует как кейс применения данного skill'а | pass |
| AC-015 | `bash scripts/check.sh --fast` — подтверждён QA-runner (exit 0); JSON-манифесты валидны | pass |
| AC-016 | Ни один живой файл в `plugins/gramax/skills/`, `agents/`, `.claude-plugin/`, `README.md`, `CHANGELOG.md` не ссылается на удалённые скрипты; orphan-hits только в разрешённых исторических локациях (ADR-архив, docs/research, docs/superpowers/specs) | pass |

**Отдельная проверка ADR-статусов (из инструкции BA-ACC):**

| ADR | Ожидаемый статус по ADR-0008 Решение 3 | Фактический статус | Соответствие |
|-----|----------------------------------------|--------------------|--------------|
| 0001 | Superseded by ADR-0008 | Superseded by ADR-0008 | pass |
| 0002 | Historical (Informational) | Historical (Informational) | pass |
| 0003 | Historical (Informational) | Historical (Informational) | pass |
| 0004 | Superseded by ADR-0008 | Superseded by ADR-0008 | pass |
| 0005 | Superseded by ADR-0008 | Superseded by ADR-0008 | pass |
| 0006 | Active | Accepted (Active) | pass |
| 0007 | Superseded by ADR-0008 | Superseded by ADR-0008 | pass |

## Functional gaps / blockers

Нет блокеров.

**Наблюдения (не блокеры):**

1. **SKILL.md writer — шаг 3 workflow.** В разделе «Diagrams (Draw.io)» шаг 3 формулирует: «Сохрани полученный файл рядом со страницей — пользователь явно указывает путь.» Формулировка технически корректна, но может быть прочитана как инструкция к действию для Claude, тогда как в spec (Migration plan, шаг 2) явно сказано, что drawio-skill создаёт файл «в CWD или явно указанном пути» — путь указывает пользователь сам. Это смысловая нечёткость, не несоответствие spec'у. Передаётся Tech-writer.

2. **`marketplace.json` description — незначительное расхождение с ADR-0008 Решение 7.** ADR предписывал новое значение `metadata.description`: «Claude Code marketplace для Gramax-документации: writer, comments, mermaid, review-agent. Drawio — через внешний плагин Agents365-ai/drawio-skill.» Фактическое значение: «...С опциональным claude-mermaid (vendored).» — добавлена фраза про claude-mermaid. Это не нарушение AC-012 (там проверяется только отсутствие запрещённых слов), и добавление информационно корректно. Фиксирую как наблюдение для PM-review: намеренное ли отклонение от ADR-таблицы.

## Notes для Tech-writer

1. **CHANGELOG.md — тон Migration-секции.** Содержимое технически полно и точно. Для финальной полировки: проверить единообразие обращения (текущий микс «ты используешь» / безличные конструкции). Рекомендация: выбрать одну форму на весь CHANGELOG и выдержать.

2. **README — раздел Drawio, предпоследняя строка.** Строка «Детали workflow и Gramax-теги для вставки — в `skills/writer/references/drawio.md`» использует путь внутри репозитория плагина. Для пользователя, установившего плагин через `marketplace add`, этот путь не является кликабельной ссылкой в Claude. Можно уточнить формулировку: «...описаны в справочнике writer-skill (drawio.md)» или оставить как есть — это авторское решение.

3. **`writer/SKILL.md` — шаг 3 двухшагового workflow.** (см. пункт 1 в Functional gaps.) Уточнить формулировку, чтобы роль пользователя в выборе пути была явной.

4. **`references/drawio.md` — раздел Troubleshooting.** Таблица симптомов содержит «Конвертировать через drawio desktop или drawio-skill» как решение. С точки зрения терминологии, «drawio-skill» без артикля может быть двусмысленным — имеется в виду именно `Agents365-ai/drawio-skill`. Рекомендуется уточнить: «через drawio desktop или внешний плагин `drawio-skill`».

## Notes для PM-review

1. **`marketplace.json` description vs ADR-0008 Решение 7.** Фактическое описание длиннее предписанного ADR (добавлена фраза «С опциональным claude-mermaid (vendored)»). Функционально корректно, но является отклонением от архитектурного решения. PM должен подтвердить: это осознанное улучшение или техдолг (потребует минорной правки ADR-0008 или явного sign-off).

2. **Versioning drift risk (RISK-004 из ADR-0008) — закрыт.** `plugin.json` и `marketplace.json` оба содержат `2.0.0`. Риск реализован не был — фиксируется как успешно митигированный.

3. **Lessons-learned.** QA-runner отметил DOC-001 (тон CHANGELOG) и рекомендовал фиксацию урока «sunset skill требует tracking ссылок в writer-references». Рекомендую PM инициировать append в `docs/lessons-learned.md` через Tech-writer или напрямую.

4. **Submodule `claude-mermaid` не затронут.** QA-runner подтвердил clean status. Граница «не редактировать submodule» соблюдена.

## Sign-off

Готово к финализации Tech-writer'ом и /pm-review.
