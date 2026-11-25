---
title: "Отчёт прохода: классификация указателей старой раскладки (FR-233) и суд по каждому спану (FR-235) — волна-4"
order: 31
status: draft
date: 2026-11-25
plugin: gramax
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Draft]
  - name: Плагин
    value: [gramax]
---

# Отчёт прохода: классификация указателей старой раскладки (FR-233) и суд по каждому спану (FR-235) — волна-4

**Опоры:** `docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md`, `docs/00-project/adr/0021-docs-layout-inversion.md`, `docs/00-project/adr/0028-wave4-validator-link-contracts.md`, `plugins/gramax/scripts/migrate_nav_codespans.py`, `tests/gramax/docs-layout-invariants/ac-003-no-content-pointers.sh`, `docs/60-implementation/acceptance/2026-11-25-wave4-contracts-gates-at-acceptance.md`

**Предмет:** AC-183, AC-184 и AC-214 требования — запись в дереве классификации 34 файлов,
чисел по каждому спану прохода и перечня переписанных спанов «до → после». **Даты:** сам
проход исполнен 2026-11-24 (коммит `98d43ef`); запись восстановлена по измерению 2026-11-25 —
черновики прохода лежали во временном каталоге машины и погибли при её перезагрузке, поэтому
каждое число ниже — команда, исполненная заново на извлечённом дереве базы `f551d87` и на
рабочем дереве. Приёмка волны-4 назвала отсутствие этой записи блокирующей находкой; здесь
она закрывается.

## Итог

| Вопрос | Число | Где |
|---|---|---|
| Файлы со спанами старой формы `content/…md` на базе `f551d87` | 34 файла, 307 спанов | раздел 1 |
| из них датированные записи | 11 файлов, 37 спанов | раздел 1 |
| из них «живые» — все цели существуют сегодня | 16 файлов, 79 спанов | раздел 1 |
| из них смешанные — есть несуществующая цель | 7 файлов, 191 спанов | раздел 1 |
| Спаны 16 живых файлов по суду прохода FR-235: переписан / чужой каталог / запись | 3 / 2 / 74 | раздел 2 |
| Строки To-migrate отчёта мигратора на базе | 26 в 15 файлах | раздел 3 |
| переведено в ссылки / принято записью | 14 / 12 | раздел 3 |
| Новые строки To-migrate в статьях волны-4: переведено / принято | 20 / 9 | раздел 3 |
| Контрольный прогон отчёта, 2026-11-25 | `To-migrate: 21` — все в принятом наборе, вне набора 0 | раздел 4 |

## 1. Классификация 34 файлов (FR-233(a), AC-183)

**Правило.** Спан — code-span, чей текст начинается с `content/` и оканчивается на `.md`.
Файлы — все `.md` под `docs/` дерева `f551d87`, где есть хотя бы один такой спан. Класс
файла: «датированная запись» — путь под `docs/60-implementation/acceptance/`,
`docs/60-implementation/test-reports/` либо файл `docs/lessons-learned.md`; иначе «живой»,
если цель каждого спана существует под `docs/` сегодня; иначе «смешанный». Цели проверялись
на рабочем дереве 2026-11-25.

| Класс | Файлов | Спанов |
|---|---|---|
| датированные записи | 11 | 37 |
| живые, все цели существуют | 16 | 79 |
| смешанные | 7 | 191 |
| всего | 34 | 307 |

### Датированные записи — 11 файлов, 37 спанов (не переписываются, BR-030)

| Спанов | Файл (под `docs/`) |
|---|---|
| 3 | `60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md` |
| 3 | `60-implementation/acceptance/2026-08-11-validation-contract-at-design.md` |
| 2 | `60-implementation/acceptance/2026-08-11-writer-consumer-rules-at-design.md` |
| 6 | `60-implementation/acceptance/2026-08-13-cross-catalog-retraction-at-design.md` |
| 7 | `60-implementation/acceptance/2026-08-13-link-form-contract-migration-at-design.md` |
| 5 | `60-implementation/acceptance/2026-08-13-link-form-contract-resolver-at-design.md` |
| 1 | `60-implementation/acceptance/2026-11-21-render-quality-wave2-at-acceptance.md` |
| 2 | `60-implementation/test-reports/2026-08-12-wave-4.2.0-qa-report.md` |
| 3 | `60-implementation/test-reports/2026-08-13-cross-catalog-retraction-qa-report.md` |
| 1 | `60-implementation/test-reports/2026-08-13-doc-root-discovery-qa-report.md` |
| 4 | `lessons-learned.md` |

### Живые файлы, все цели существуют — 16 файлов, 79 спанов (исходный набор прохода FR-235)

| Спанов | Файл (под `docs/`) |
|---|---|
| 5 | `10-domain/research/2026-08-11-index-md-at-catalog-root.md` |
| 1 | `10-domain/research/2026-08-11-plugin-consumers-gaps.md` |
| 4 | `60-implementation/2026-08-13-cross-catalog-retraction-dev-notes.md` |
| 2 | `60-implementation/2026-08-13-doc-root-discovery-dev-notes.md` |
| 1 | `60-implementation/2026-08-13-link-form-contract-migration-dev-notes.md` |
| 8 | `30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` |
| 2 | `30-requirements/2026-08-11-validation-contract.md` |
| 8 | `30-requirements/2026-11-17-docs-layout-inversion.md` |
| 1 | `00-project/adr/0008-drop-internal-drawio-skills.md` |
| 1 | `00-project/adr/0009-drawio-stub-and-claude-mermaid-removal.md` |
| 1 | `00-project/adr/0010-mermaid-file-based-workflow.md` |
| 1 | `00-project/adr/0012-catalog-validation-contract.md` |
| 4 | `00-project/adr/0015-root-index-inert.md` |
| 11 | `00-project/adr/0017-cross-catalog-retraction.md` |
| 11 | `00-project/adr/0018-link-form-version-authorization.md` |
| 18 | `00-project/security/audit-2026-08-13-link-form-wave.md` |

### Смешанные — 7 файлов, 191 спанов (вне набора прохода)

| Спанов | Целей нет | Файл (под `docs/`) | Что за отсутствующие цели |
|---|---|---|---|
| 159 | 18 | `10-domain/research/2026-08-13-link-form-corpus-audit.md` | шаблоны (`content/*.md`, `content/<путь>.md`, `content/article.md`) и имена удалённых артефактов в таблицах находок |
| 4 | 4 | `10-domain/research/2026-08-13-link-forms-probe.md` | шаблоны |
| 4 | 1 | `60-implementation/2026-08-11-validation-contract-dev-notes.md` | `content/article.md` |
| 7 | 6 | `30-requirements/2026-08-13-link-form-contract.md` | шаблоны формы ссылки — предмет самого требования |
| 4 | 3 | `00-project/adr/0016-link-form-contract.md` | шаблоны формы ссылки |
| 12 | 2 | `00-project/adr/0021-docs-layout-inversion.md` | `content/40-architecture/ADR-018-…-spec.md`, `content/10-domain/glossary.md` |
| 1 | 1 | `40-architecture/2026-08-13-link-form-contract-design.md` | `content/section/doc.md` |

Смешанные файлы не являются предметом точечного прохода: у их спанов либо нет цели (шаблон,
удалённый артефакт), либо они говорят о чужом каталоге или о конвенции; живой страж
`ac-003-no-content-pointers.sh` покрывает их построчными и пофайловыми правилами Решения 3
ADR-0021 и зелёный.

## 2. Суд по каждому спану прохода FR-235 (AC-214)

**Правило.** Для каждого из 79 спанов 16 живых файлов: «переписан» — на рабочем дереве строка
уже не несёт спан старой формы; иначе класс файла или строки по правилам живого стража
(`file_excluded`, `line_allowed`): «запись» — файл исключён как RECORD (ADR, аудит
безопасности, dev-notes, пробы 2026-08, требование миграции, требование самой инверсии);
«чужой каталог» — строка говорит о каталогах потребителей; «конвенция» — строка о форме
ссылки экосистемы.

| Класс спана | Спанов |
|---|---|
| переписан на путь `docs/` | 3 |
| упоминание чужого каталога | 2 |
| запись (не переписывается) | 74 |
| упоминание конвенции | 0 |
| всего | 79 |

### Переписанные спаны — «до → после»

| Файл | Строка на базе | Строка сейчас | До | После |
|---|---|---|---|---|
| `docs/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | 346 | 369 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | `docs/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` |
| `docs/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | 364 | 387 | `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | `docs/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` |
| `docs/30-requirements/2026-11-17-docs-layout-inversion.md` | 313 | 316 | `content/30-requirements/2026-11-17-docs-layout-inversion.md` | `docs/30-requirements/2026-11-17-docs-layout-inversion.md` |

Все три — указатель статьи на саму себя в шапке встроенной копии протокола (`**Требование:**`);
цель существует под `docs/`, предложение — о собственном файле репозитория: оба условия FR-235
выполнены. Коммит — `98d43ef`.

### Упоминания чужого каталога — 2 спана (не переписываются)

`docs/30-requirements/2026-08-11-validation-contract.md`, строки 70 и 279 на базе: спан
`content/_index.md` в предложениях «…присутствует во всех пяти…» и «…в пяти внешних
докъ-репозиториях…» — речь о каталогах потребителей, не об этом дереве.

### Записи — 74 спана (не переписываются)

| Спанов | Класс файла по стражу | Файлы |
|---|---|---|
| 30 | исторические ADR (кл.1) | ADR-0008, 0009, 0010, 0012, 0015, 0017, 0018 |
| 18 | аудит безопасности завершённой волны (кл.2) | `docs/00-project/security/audit-2026-08-13-link-form-wave.md` |
| 7 | dev-notes (кл.2) | три `*-dev-notes.md` под `docs/60-implementation/` |
| 6 | пробы 2026-08, записи замеров на дату и чужие деревья (кл.6) | `2026-08-11-index-md-at-catalog-root.md`, `2026-08-11-plugin-consumers-gaps.md` |
| 6 | требование миграции 2026-08-09 (кл.2, RECORD) | `docs/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` |
| 7 | требование самой инверсии (кл.1) | `docs/30-requirements/2026-11-17-docs-layout-inversion.md` |

## 3. Отчёт мигратора навигационных спанов (FR-233(b), AC-184)

**Команда:** `PYTHONDONTWRITEBYTECODE=1 python3 -B plugins/gramax/scripts/migrate_nav_codespans.py docs`.

### База `f551d87`: 26 строк To-migrate в 15 файлах

`To-migrate: 26`, `SELF: 22`, `SUBJECT: 203` — совпадает с фактом 3 требования.

**Переведено в ссылки — 14 строк** (13 — коммит `98d43ef`, 1 — 2026-11-25). Форма ссылки —
как у мигратора: текст — `title` цели, адрес — относительный путь с `.md`.

| Файл (под `docs/`) | Строка на базе | Строка сейчас | Было (code-span) | Стало |
|---|---|---|---|---|
| `30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | 183 | 186 | `docs/onboarding-nauta.md` | `[Онбординг: роли nauta на чистой машине](../onboarding-nauta.md)` |
| `30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | 185 | 186 | `docs/onboarding-nauta.md` | та же ссылка |
| `30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md` | 186 | 186 | `docs/onboarding-nauta.md` | та же ссылка |
| `30-requirements/2026-11-17-docs-layout-inversion.md` | 117 | 120 | `docs/lessons-learned.md` | `[Lessons Learned — gramax marketplace](../lessons-learned.md)` |
| `30-requirements/2026-11-17-docs-layout-inversion.md` | 149 | 152 | `docs/_index.md` | `[Документы](../_index.md)` |
| `30-requirements/2026-11-17-docs-layout-inversion.md` | 271 | 152 | `docs/_index.md` | `[Документы](../_index.md)` |
| `30-requirements/2026-11-18-plantuml-bpmn-requirement.md` | 78 | 83 | `docs/00-project/adr/0008-drop-internal-drawio-skills.md` | `[ADR-0008: Удаление внутренних drawio-skills и делегирование внешнему плагину](../00-project/adr/0008-drop-internal-drawio-skills.md)` |
| `30-requirements/2026-11-18-plantuml-bpmn-requirement.md` | 124 | 131 | `docs/30-requirements/2026-08-11-mermaid-file-based-adoption.md` | `[Принятие file-based mermaid потребителями — граница юрисдикции, обнаружение и миграция устаревшего формата](2026-08-11-mermaid-file-based-adoption.md)` |
| `30-requirements/2026-11-18-plantuml-bpmn-requirement.md` | 162 | 131 | `docs/30-requirements/2026-08-11-mermaid-file-based-adoption.md` | та же ссылка |
| `30-requirements/2026-11-18-validators-error-check-parity-requirement.md` | 97 | 102 | `docs/30-requirements/2026-08-11-mermaid-file-based-adoption.md` | та же ссылка |
| `30-requirements/2026-11-18-validators-error-check-parity-requirement.md` | 98 | 103 | `docs/10-domain/research/2026-08-11-index-md-at-catalog-root.md` | `[`_index.md` в корне Gramax-каталога: что запрещает скилл, что требует валидатор, что делает движок](../10-domain/research/2026-08-11-index-md-at-catalog-root.md)` |
| `30-requirements/2026-11-21-render-quality-wave2-requirements.md` | 187 | 193 | `docs/lessons-learned.md` | `[Lessons Learned — gramax marketplace](../lessons-learned.md)` |
| `30-requirements/2026-11-21-render-quality-wave2-requirements.md` | 252 | 193 | `docs/lessons-learned.md` | та же ссылка |
| `40-architecture/2026-11-21-render-quality-wave2-design.md` | 308 | 308 | `docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md` | `[Запись замера: судьба th-правила validate_render по повторному факту рендера (волна-2, FR-199/FR-200)](../60-implementation/acceptance/2026-11-21-render-calibration-th.md)` |

**Принято записью — 12 строк.**

| Строк | Класс | Где |
|---|---|---|
| 10 | датированные записи (acceptance, test-reports) — BR-030 | `2026-11-18-export-skill-at-design.md`:166; `2026-11-18-plantuml-bpmn-at-design.md`:167; `2026-11-18-validators-parity-at-design.md`:160; `2026-11-18-writer-sync-470-at-design.md`:202; `2026-11-21-render-quality-wave2-at-acceptance.md`:85; `2026-11-21-render-quality-wave2-at-design.md`:101, :118, :177; `2026-11-23-wave3-at-acceptance.md`:87; `2026-11-18-qa-057-docs-layout-inversion-full-run.md`:137 (нумерация базы) |
| 2 | замороженный ADR | `docs/00-project/adr/0014-dual-publication-targets.md`:99, :158 (нумерация базы; сейчас :101, :160) — строки цитируются дословно в ADR-0030 (цитата с указанием строк `0014-dual-publication-targets.md:97-99`), переписывание ломало бы цитату |

### Статьи волны-4: 29 новых строк To-migrate

Замер 2026-11-25 до завершения прохода: `To-migrate: 40`; ещё две строки добавили
датированные поправки PM к AC-183 и AC-184 (указатели на этот отчёт) — приёмка поймала
их контрольным прогоном (`To-migrate: 23`).

**Переведено — 20 строк** (2026-11-25; мигратор в режиме `--fix` не применялся: он действует
на весь doc-root и переписал бы датированные записи и цитаты, — те же 19 замен, включая строку
дизайна волны-2 из таблицы выше, исполнены точечно, той же формой ссылки):

| Строк | Файл (под `docs/`) |
|---|---|
| 9 | `30-requirements/2026-11-24-wave4-docs-decisions-requirement.md` |
| 5 | `40-architecture/2026-11-24-wave4-privacy-disposition.md` |
| 2 | `00-project/adr/0029-wave4-gate-suite-composition.md` |
| 1 | `00-project/adr/0028-wave4-validator-link-contracts.md` |
| 1 | `00-project/adr/0030-plugin-perimeter-deferred-capabilities.md` |
| 2 | `30-requirements/2026-11-24-wave4-contracts-gates-requirement.md` |

**Принято — 9 строк:** дословная цитата ADR-0014 в ADR-0030 (строка 262); датированные записи
волны-4 — `2026-11-24-wave4-gates-at-design.md` (3), `2026-11-24-wave4-docs-at-design.md` (2),
запись приёмки половины A (2), QA-отчёт волны-4 (1).

## 4. Контрольный прогон

| Замер | Результат |
|---|---|
| 2026-11-25, после точечного перевода | `To-migrate: 21`, `SELF: 26`, `SUBJECT: 557` |
| из них принято записью (раздел 3) | 21 = 12 строк базы + 9 строк статей волны-4 |
| вне принятого набора | 0 |
| повторный контроль, 2026-11-25, после переписывания QA-отчёта волны-4 | `To-migrate: 20` — строка QA-отчёта стала ссылкой; вне принятого набора 0 |

`bash scripts/check.sh --fast` после правок — Errors 0 (в момент записи единственные строки
расхождений относятся к регистрации самой этой записи и записи приёмки — их индексные строки
ставит PM тем же коммитом).

## 5. Поправки к требованию (PM, 2026-11-25)

Обе — датированные поправки к измеряемым числам AC, без изменения смысла:

- **AC-183.** Числа классов в тексте AC (40 / 72 / 195) — первая редакция факта 4, которую
  факт 4 уже пересчитал («пересчёт по ралинг PM»: 37 / 79 / 191); повторный замер 2026-11-25
  подтверждает факт 4. Действующие числа — таблица раздела 1.
- **AC-184.** «16 строк переведены» по факту: 14 переведены, 2 приняты записью (замороженный
  ADR-0014, цитируемый в ADR-0030); принято всего 12 строк базы плюс 9 строк статей волны-4.
  Строка «Опоры», названная в факте 3 отдельно от девяти датированных, на дереве базы маркером
  `**Опоры:**` среди 26 строк не находится — десять строк датированных записей приняты целиком.
