---
title: "Приёмка (BA-acceptance): writer 4.7.0 — массовая синхронизация скилла с движком 48592b36 и документацией gram.ax"
order: 13
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# Приёмка (BA-acceptance): writer 4.7.0 — массовая синхронизация скилла с движком 48592b36 и документацией gram.ax

**Опоры:** `docs/30-requirements/2026-11-18-writer-sync-470-requirement.md`,
`docs/40-architecture/2026-11-18-writer-sync-design.md`,
`docs/10-domain/research/2026-11-18-writer-docs-divergence-audit.md`,
`tests/gramax/writer-sync-470/README.md`, `plugins/gramax/skills/writer/SKILL.md`

**Роль:** BA-acceptance gate — финальный гейт волны 4.7.0 (порядок 13). Проверка AC-073…AC-096 и
FR-161…FR-182 требования против **реализованных** файлов writer (не против обещаний дизайна),
с собственным повторным исполнением буквальных формул AC, собственных грепов четырёх override'ов
RES-008 и собственного дифа контракта тегов, с вердиктом.
**Дата приёмки:** 2026-11-18
**Требование:** [writer 4.7.0 — массовая синхронизация скилла с окном движка 48592b36](../../30-requirements/2026-11-18-writer-sync-470-requirement.md) (AC-073…AC-096, FR-161…FR-182, BR-015…BR-018)
**Дизайн:** [2026-11-18-writer-sync-design.md](../../40-architecture/2026-11-18-writer-sync-design.md) (Q1–Q6, диф контракта NFR-072, таблица FR→файл, контракт с QA-author)
**Факт-база:** [RES-008](../../10-domain/research/2026-11-18-writer-docs-divergence-audit.md) (пять вердиктов по исходнику движка, пин `48592b36`) — четыре существенных для требования переигрывания проверены ниже собственными грепами, не цитированием
**Реализация:** коммит `03011ee` (red-phase `c255f98`, дизайн `a59db10`) — `plugins/gramax/skills/writer/SKILL.md` (438 строк), `references/blocks.md` (560), NEW `references/quizzes.md` (136), `references/doc-root-schema.md` (279), `references/structure.md` (+16 строк), `plugins/gramax/gramax-tags.json` (+9/+4 тега), миграция `docs/.doc-root.yaml` (`filterProperties` → `filterProperty`); footprint ровно план файлов дизайна
**QA-отчёт:** [QA Report writer-sync-470](../test-reports/2026-11-18-writer-sync-470-qa-report.md) — независимый прогон 24/24, рекомендация **accept** (принята как вход, не как замена собственной проверке)
**Suite:** `tests/gramax/writer-sync-470/` (24 скрипта, 1:1 к AC-073…AC-096)
**Метод:** каждый AC — проверка из требования, свидетельство реализации (файл:строка), собственный дословный прогон формулы AC, вердикт PASS/FAIL. Каждый FR — implemented/partial/none со свидетельством. Известные дефералы классифицируются accepted-deviation или дефект. Не-покрытия — not-covered-with-owner, никогда не pass.

---

## Summary

| Метрика | Значение |
|---|---|
| AC | **24 pass / 0 fail** (AC-073…AC-096) |
| FR | **22 implemented / 0 partial / 0 none** (FR-161…FR-182); из них 2 — с engine-обоснованными accepted-deviation от буквы (FR-167, FR-168 — раздел «Находки») |
| Override'ы RES-008 | 4/4 подтверждены собственными грепами BA (BR-015) |
| Контракт NFR-072 | диф `gramax-tags.json` — точно 9+4, `schemaVersion` 2, `snippet`/`diagramTags` не тронуты (собственный diff) |
| Миграция doc-root | `filterProperty: Тип контента` на месте (`docs/.doc-root.yaml:32`), старой формы нет (собственный diff) |
| Дефералы | 3 релизных (CHANGELOG `Contract:`, bump версии, композитная обусловленность) + 3 ревью-пункта — все accepted-deviation/not-covered с владельцами; 0 дефектов |
| Гейты | Backlog-closure `✓ n/a`; Breaking-change-guide `✓ n/a`; Downstream-test-touch `N/A` |
| Вердикт | **accept** (блокеров нет; список неблокирующих действий PM/Tech-writer — в конце) |

Собственные прогоны BA на момент приёмки (дерево до записи этого файла): `bash
tests/gramax/writer-sync-470/run.sh` → **24/24, rc=0**; дословные формулы AC-073…AC-095 из
раздела Acceptance Criteria требования исполнены собственной рукой — **все 23 PASS**; композитный
гейт AC-096 — `bash scripts/check.sh --fast` → **rc=0, RESULT: PASS**; спот-чек соседа
plugin-contract — **7/7**. После записи этого файла гейт и ac-096 детерминированно краснеют ровно
на одну собственную C1 (файл не зарегистрирован в `acceptance/_index.md` — PM wires) — env-класс,
«Находки» №4.

---

## AC coverage (AC-073…AC-096)

Колонка «Прогон BA» — моё собственное исполнение дословной формулы требования (не пересказ QA и
не stab suite); suite-прогон 24/24 — тот же момент дерева. Свидетельства — `файл:строка` HEAD
`03011ee` (плюс незакоммиченный QA-отчёт, на writer не влияет).

| AC | Проверка из требования (предмет) | Свидетельство реализации | Прогон BA | Вердикт |
|---|---|---|---|---|
| AC-073 (FR-161) | grep `searchPhrases` по SKILL.md + references | строка таблицы «Дополнительные ключи» `SKILL.md:139` (эффект, регистр, часть слова — RES-007 §2) | PASS | **PASS** |
| AC-074 (FR-162) | grep `aliases` по SKILL.md + references | `SKILL.md:140`; шаг 5 «Переместить статью» `structure.md:74-86`; «Переместить раздел» шаг 3 `:92-94` | PASS | **PASS** |
| AC-075 (FR-163) | `quizzes.md` существует + `questionAnswer`/`showIf`/`countOfCorrectAnswers` | файл 136 строк; `<questionAnswer>` `:35-47`; `showIf` `:95-109`; `countOfCorrectAnswers` `:123,131` | PASS | **PASS** |
| AC-076 (FR-163) | редчайшие `ranking` + `matrix` в quizzes.md | полный перечень 12 типов таблицей `quizzes.md:51-67` | PASS | **PASS** |
| AC-077 (FR-164) | `<cut`/`<property`/`<inline-property` в blocks.md | раздел «Скрытые фрагменты и привязки» `blocks.md:68-102` (атрибуты `text`/`expanded` `:76-79`, `id`/`value` `:85-93`, `bind` `:95-102`) | PASS | **PASS** |
| AC-078 (FR-165) | `orderby` + `Kanban` + «скрыт» в blocks.md | таблица атрибутов `<view>` `blocks.md:119-127` (`orderby` `:124`, `Kanban` `:127`, «сокрытия… скрыты» `:123`) | PASS | **PASS** |
| AC-079 (BR-015/BR-016) | нет форм `<gallery` и `display="Gantt"` в дереве writer | **собственный счётчик BA**: `<gallery` → 0, `display="Gantt"` → 0; слово «Gantt» единожды в негативной прозе без литеральной формы (`blocks.md:127`) | PASS | **PASS** |
| AC-080 (FR-166) | `<cmd text=` + `<kbd text=` + `[cmd:` в blocks.md | XML-формы `blocks.md:441-444`, скобочные таблица `:456-463` | PASS | **PASS** |
| AC-081 (FR-167) | `scale=` + дословное «реальный размер» в blocks.md | `scale` XML-формы `blocks.md:377-381`; «реальный размер файла в пикселях» `:372` (и `SKILL.md:274`) | PASS | **PASS** |
| AC-082 (FR-168) | `dropbox` + `mega` + `cover` в blocks.md | хостинги `blocks.md:308-309`; слово `cover` — в негативной пометке Q4 `:324-325` (употребление негативное — «Находки» №3) | PASS | **PASS** |
| AC-083 (FR-169) | `showSchemas` + `showInfo` в blocks.md | раздел OpenAPI `blocks.md:283-291`, формат YAML/JSON `:289-290` | PASS | **PASS** |
| AC-084 (FR-170) | «блок кода» + `highlight.js` в blocks.md | раздел «Блок кода» `blocks.md:245-266` (обёртка в четыре кавычки `:259-266`) | PASS | **PASS** |
| AC-085 (FR-171) | `{#` в blocks.md | раздел «Якоря заголовков» `blocks.md:268-281`; строка в SKILL.md «Ссылки» `:228` | PASS | **PASS** |
| AC-086 (FR-172) | `<fragment id=` + `fragment-link` + `legacy` + «фрагмент» в SKILL.md | раздел «Фрагменты» `blocks.md:161-187` (legacy-пометка `:179-187`); строка таблицы `SKILL.md:313` | PASS | **PASS** |
| AC-087 (FR-173) | «без .md» + одна из трёх фраз оговорки в SKILL.md | правило `SKILL.md:225-226`; оговорка «обе формы резолвятся движком и офлайн-валидатором» `:231-234`; миграция не вводится | PASS | **PASS** |
| AC-088 (FR-174) | `logo_dark`/`relatedLinks`/`versions`/`hidden` + regex `filterProperty([^i]|$)` | таблица «Корневые ключи» `doc-root-schema.md:23-31` (`filterProperty` `:31`; legacy-форма `filterProperties` помечена `:34-38`, регэксп её не матчит — проверено) | PASS | **PASS** |
| AC-089 (FR-175) | `GitHub Flavored Markdown` + `blue-pink\|orange-red` | enum syntax `doc-root-schema.md:40-53`; палитра 20 значений `:102-108` | PASS | **PASS** |
| AC-090 (FR-176) | `.gramax/views` в дереве writer | таблица «Служебные папки» `doc-root-schema.md:148` (+staging `SKILL.md:392`) | PASS | **PASS** |
| AC-091 (FR-177) | `lfs` + `.gitattributes` в doc-root-schema.md | ключ `lfs` `doc-root-schema.md:28`; `.gitattributes` `:152`; LFS-указатели в Guardrails `SKILL.md:417-418` | PASS | **PASS** |
| AC-092 (FR-178) | «мультиязыч» + «непереведён» в references | раздел «Мультиязычность» `doc-root-schema.md:134-142` (правило 3 «непереведён» `:141`) | PASS | **PASS** |
| AC-093 (FR-179) | `docportalVisible` + `\bFlag\b` + `\bNumeric\b` | шесть имён движка `doc-root-schema.md:75`; `options.docportalVisible` `:64-65,78` | PASS | **PASS** |
| AC-094 (FR-180) | `.icons/` в дереве writer | `doc-root-schema.md:151` + раздел «Иконки» `blocks.md:337-349` | PASS | **PASS** |
| AC-095 (FR-181/182) | `template:`/`.gramax/templates`/`.gramax/inbox`/`.gramax/mr` в SKILL.md | hard rule шаблонов `SKILL.md:408-414`; inbox/mr `:415-416`; staging п.3 `:393` | PASS | **PASS** |
| AC-096 (композитный) | `bash scripts/check.sh --fast` → rc=0 | **собственный прогон BA** на вердиктном состоянии: rc=0, `RESULT: PASS`; ac-096 стаба PASS в suite-прогоне | PASS | **PASS** |

Дополнительно к формуле (собственные проверки BA): NFR-072-диф `gramax-tags.json` — собственный
`git diff a59db10..HEAD`: `selfClosingTags` +9 (fragment, property, inline-property, img-h,
img-v, cmd, kbd, alfa, beta), `pairedTags` +4 (fragment-link, cut, question, questionAnswer),
`schemaVersion` 2, `snippet` и `diagramTags` не тронуты — точное соответствие контракту дизайна;
миграция `docs/.doc-root.yaml` — собственный diff: строка `filterProperties: [Тип контента,
Статус, Плагин]` удалена, внесён `filterProperty: Тип контента` с комментарием-обоснованием
(`CatalogProps.ts:17`; RES-008 Q1б), ключ на месте `:32`.

## Четыре override'а RES-008 (BR-015) — собственные грепы BA, не цитирование

| # | Override | Наблюдение BA (всё дерево `plugins/gramax/skills/writer/`) | Вердикт |
|---|---|---|---|
| 1 | Без `<gallery>` и `Gantt` | `<gallery` → 0 вхождений; `display="Gantt"` → 0; «Gantt» единожды — негативная проза без литеральной формы (`blocks.md:127`, «в движке на пине отсутствует — не указывать») | соответствует |
| 2 | Ссылки: правило + оговорка | правило «без .md» сохранено (`SKILL.md:225-226,232`); оговорка «обе формы резолвятся движком и офлайн-валидатором… не канонический… миграция не обязательна» (`:231-234`); BR-017 соблюдена | соответствует |
| 3 | `<view>`: `defs` — сокрытие | таблица `blocks.md:123` — «Фильтр сокрытия: перечисленные значения исключают статьи…; `none` — только статьи, у которых свойство есть; `yes` — только без него»; `hierarchy=child-to-current` — запись внутри `defs` (`:112`, `:129-130`, `SKILL.md:333`, «не атрибутом тега»); старый перевёрнутый пример (`Тип контента=ADR&Архитектура&none`) → 0 вхождений; единственное «фильтром отбора» — в пометке NFR-071 о том, что старая формулировка была обратной (`blocks.md:144-147`) | соответствует |
| 4 | Изображения: scale/размеры | «реальный размер файла» (`blocks.md:372`, `SKILL.md:274`); `scale` — только XML-форма `<image scale="…"/>` (`:377-381`) и видео (`:316`); markdown-аннотация ограничена width/height с оговоркой (`:359-360`); `{scale` → 0 вхождений — слепая зона дизайна чиста | соответствует |

Негатив `cover` (Q4): слово — единожды, в негативной пометке `blocks.md:324-325`; форма атрибута
`cover=` → 0 вхождений. Соответствует дизайну Q4 и BR-015.

---

## FR coverage (FR-161…FR-182)

| FR | Требование (кратко) | Реализация (файл:строка) | Статус |
|---|---|---|---|
| FR-161 | `searchPhrases` в секции Frontmatter SKILL.md | таблица «Дополнительные ключи» `SKILL.md:135-142`, строка `:139` с эффектом по RES-007 §2 | **implemented** |
| FR-162 | `aliases` в разделах переноса structure.md | `structure.md:74-86` (шаг 5, форма «без .md», автозапись UI) + шаг 3 переноса раздела `:92-94` + `SKILL.md:140` | **implemented** |
| FR-163 | справочник `quizzes.md`: question/questionAnswer, 12 типов, showIf, quiz-ключ; серверная сторона вне | весь файл `quizzes.md`: атрибуты `:25-33`, `:40-47` (+engine-дополнение questionId/type «не нужны» `:45-47`); camelCase-ограничение `:31-33`; 12 типов `:51-73`; `showIf` `:95-109`; `quiz` `:111-136`; GES-исключение `:5-7,135-136` | **implemented** |
| FR-164 | `<cut>`, `<property/>`, `<inline-property/>` в blocks.md | `blocks.md:70-83` (text/expanded, инлайн vs блочная-legacy), `:85-93` (id/value, подстановка версии), `:95-102` (bind) | **implemented** |
| FR-165 | rewrite `<view>` по вердикту 3: defs-сокрытие, none/yes, orderby, select, display List/Table/Kanban, hierarchy через defs | `blocks.md:104-159` (таблица `:119-127`, none/yes-примеры `:132-142`, пометка NFR-071 `:144-147`, правило `id ?? name` `:156-159`); `SKILL.md:322-340` | **implemented** |
| FR-166 | XML-формы cmd/kbd/alfa/beta канон для XML; скобочные валидны; `[color:]` парность; legacy `<kbd>` пометка | `blocks.md:435-468`: XML `:440-452` (атрибут `color` `:441,449`), скобочные `:454-463`, `[color:]…[/color]` `:465`, legacy `<kbd>` `:467-468` | **implemented** |
| FR-167 | `scale` (px/проценты), width/height — реальные размеры файла, без `<gallery>`; img-h/img-v — кандидат SA | `blocks.md:370-384` (семантика по движку с `путь:строка`), img-h/img-v включены по Q2 с пометкой HTML-фолбэка `:386-398`, галерея — негатив `:400-401`. Accepted-deviation от буквы «в обеих формах»: `scale` только XML-формой (markdown-ограничение `:359-360`) — точно по строке дизайна FR-167, engine-факт `imgSizePlugin.ts:24-25` («Находки» №2) | **implemented** |
| FR-168 | видео: Dropbox, Mega; title, scale, cover | хостинги (семь) `blocks.md:307-310`; `title`/`scale` engine-верифицированы `:312-317`; embed-правило рендера (Q4) `:319-322`; строка таблицы `SKILL.md:318`. Accepted-deviation от буквы по `cover`: негативная пометка `:324-325` — в движке на пине атрибут отсутствует, BR-015 требования ставит движок выше docs («Находки» №3) | **implemented** |
| FR-169 | OpenAPI: showSchemas, showInfo, YAML/JSON | `blocks.md:283-291`, пометка источника «engine-проб не проводился» `:290` — по строке дизайна | **implemented** |
| FR-170 | выделенный раздел «Блок кода», highlight.js, четыре кавычки | `blocks.md:245-266` | **implemented** |
| FR-171 | якоря `{#имя}` + ссылка на якорь | `blocks.md:268-281` (engine `headingFormatter.ts:6`); `SKILL.md:228` | **implemented** |
| FR-172 | канон `<fragment>`+`.gramax/fragments/`, `<fragment-link>`, `<snippet>` legacy, staging «фрагменты/сниппеты» | `blocks.md:161-187` (канон `:163-177`, legacy + «мигрирует при первой правке», без рецепта миграции — Q5 `:179-187`); `SKILL.md:313`, staging п.2 `:392`, Guardrails `:407` | **implemented** |
| FR-173 | правило «без .md» сохранено + оговорка о резолве `.md`-формы; миграции нет | `SKILL.md:225-234` — дословно по формулировке дизайна; BR-017 соблюдена | **implemented** |
| FR-174 | ключи logo/logo_dark, versions, relatedLinks, lfs, hidden | таблица «Корневые ключи» `doc-root-schema.md:23-29` — все engine-верифицированы с `путь:строка` (формы `icon:<код>[:<цвет>]`/`emoji:` `:23-24` — деталь цвета из Q1д); полный пример `:222-269` | **implemented** |
| FR-175 | enum syntax три значения, палитра 20 + legacy, filterProperty/filterProperties, пометки источников | `doc-root-schema.md:40-53` (пометка деградации `syntax: Markdown` → `Legacy` `:49-53`); палитра `:98-116` (20 enum `:102-108`, legacy-строка 11 с 6 вне-enum `:110-116`); `filterProperty` `:31` + legacy-форма `:34-38`; каждая строка несёт источник (engine/docs) — механизм FR-175 соблюдён | **implemented** |
| FR-176 | `.gramax/views` — хранилище представлений, не изобретать, не удалять | `doc-root-schema.md:148` (engine `CatalogViewProvider.ts:26`); staging `SKILL.md:392` («представления») | **implemented** |
| FR-177 | `.gitattributes`, ключ `lfs`, указатели LFS в «не трогать» | `doc-root-schema.md:28,152`; Guardrails `SKILL.md:417-418` | **implemented** |
| FR-178 | правила мультиязычности (4 правила) | `doc-root-schema.md:134-142` — все четыре, источник docs помечен; размещение doc-root-schema — решение SA дизайна (перенос отклонён) | **implemented** |
| FR-179 | типы свойств по именам движка, id-нотация, docportalVisible, «переименовать нельзя» | `doc-root-schema.md:55-96`: шесть имён `:75`, `id ?? name` `:73-74`, id-нотация канон + name-фолбэк `:81-87`, `docportalVisible` `:64-65,78`, String-расхождение помечено не молча `:89-92`, запрет переименования с docs-пометкой `:94-96` | **implemented** |
| FR-180 | `.icons/` механизм | `doc-root-schema.md:151` + `blocks.md:337-349` (граница с валидатором названа `:347-349`) | **implemented** |
| FR-181 | hard rule `template:` + механизм + политика правки файлов шаблонов | `SKILL.md:408-414` — правило + Q3-политика (файл шаблона — только по явному запросу; тело пусто by design, не «восстанавливать»); механизм `:142`, `doc-root-schema.md:150` | **implemented** |
| FR-182 | hard rules `.gramax/inbox/`, `.gramax/mr/` (Guardrails + staging) | `SKILL.md:415-416` + staging п.3 `:393` | **implemented** |

## NFR (краткий разбор)

- **NFR-070 (навигационная дисциплина)** — satisfied: плотность в references (quizzes.md 136,
  blocks.md 560, doc-root-schema 279 строк); SKILL.md 438 строк — строки-указатели и hard rules;
  `description` frontmatter побайтно не менялся с `a59db10` (собственный diff — 0 строк).
- **NFR-071 (аддитивность)** — satisfied: `snippet` валиден-legacy (контракт + `blocks.md:179-187`);
  скобочные формы валидны (`blocks.md:454-463`); правило FR-080 сохранено; legacy-строки палитры/
  `filterProperties`/`syntax: Markdown`/name-нотации помечены, не объявлены невалидными.
- **NFR-072 (контракт тегов)** — satisfied: диф точно по контракту дизайна (9+4, schemaVersion 2,
  snippet/diagramTags не тронуты — собственный diff); одно изменение с правками writer (коммит
  `03011ee`); условие одного релизного окна с ADR-0024-потоком соблюдено (validators-parity принят
  12/12 сегодня, запись `Contract:` — релизный коммит, «Действия вне гейта» п.2).
- **NFR-073 (язык и форма примеров)** — satisfied: новые фрагменты на русском, примеры рабочие
  (quizzes `:14-23,77-93`, view `:111-117`, фрагменты, property), синтаксис — в ограждённых
  код-блоках/спанах; render-линтер-гейт в составе `check.sh --fast` зелёный.

---

## Известные дефералы — классификация BA

| # | Деферал | Факт (собственная проверка BA) | Классификация | Владелец |
|---|---|---|---|---|
| 1 | Запись `Contract:` 4.7.0 в `plugins/gramax/CHANGELOG.md` | `grep '4\.7\.0\|Contract'` — только исторические записи (строки 68, 115, 153, 234), записи 4.7.0 нет | **accepted-deviation** — по дизайну это шаг 7 «Порядка правок» (Dev/Tech-writer), приуроченный к единому релизному коммиту волны (NFR-068 release-flow); прецедент предыдущей волны (plantuml: release-surface после приёмки); ни один AC записи не требует | PM/Tech-writer — до release, обязательно (NFR-072) |
| 2 | Bump версии 4.6.0 → 4.7.0 (`plugin.json`, `marketplace.json`) | собственный grep: оба файла `"version": "4.6.0"` | **accepted-deviation (плановое состояние)** — NFR-071 требования прямо выносит semver из среза («решение PM/SA при выпуске, не этого требования»); дизайн «Решение по ADR» п.3 (ADR-0006-зона) | Tech-writer/PM при выпуске |
| 3 | Композитная обусловленность AC-096 после записи отчётов | вердиктное состояние — rc=0 (мой прогон); после записи QA-отчёта и этого файла — ожидаемая own-file C1 до PM-регистрации (QA «Постпроверка» + «Находки» №4 здесь) | **accepted-deviation (env-класс)** — снимается регистрацией двух строк в `_index.md` без правки кода/тестов | PM |

## Не-покрытия ревью-пунктами (not-covered-with-owner — никогда не pass)

| # | Пункт | Состояние на прогоне (собственная проверка BA) | Владелец |
|---|---|---|---|
| 1 | markdown-форма `{scale=…}` — слепая зона AC-081 | **чиста**: `{scale` → 0 вхождений по дереву writer; `scale` дан XML-формой с явной markdown-оговоркой (`blocks.md:359-360`) | ревьюер — процессная проверка при следующих правках раздела изображений |
| 2 | AC-075 — docs-поверхность GES (`showIf`, `mode`, `shuffleQuestions`, 9 типов) — строковые проверки без engine-семантики | пометки источников на месте: `showIf` «в OSS-дереве не найден — поверхность GES» (`quizzes.md:108-109`), `mode`/`shuffleQuestions` «docs» (`:132-133`) | SA/PM — верификация при первом окне с исходниками GES (открытый вопрос 3 дизайна) |
| 3 | AC-082 — амбивалентность `cover` (позитивный grep не различает употребление) | употребление негативное (`blocks.md:324-325`), форма `cover=` → 0 вхождений | ревьюер — процессная проверка |

---

## Находки: отклонения дизайн↔реализация

| # | Находка | Классификация | Основание |
|---|---|---|---|
| 1 | Миграция `docs/.doc-root.yaml` исполнена Dev внутри коммита потока `03011ee`, тогда как текст дизайна (Q1б) назначал её PM («правка не входит в срез writer») | **accepted-deviation** | Бриф координатора этой волны прямо называет миграцию частью реализации под приёмку («migrated key» во входах); содержимое миграции точно по вердикту Q1б (собственный diff); зафиксировано для истории — расхождение снято брифом, не молчанием |
| 2 | FR-167: `scale` задокументирован только XML-формой, не «в обеих формах» буквы FR | **accepted-deviation** | Точно по строке дизайна FR-167: engine-факт — markdown-аннотация применяет только `width`/`height` (`imgSizePlugin.ts:24-25`); задокументировать `{scale=…}` как рабочий значило бы нарушить инвариант «каждое утверждение несёт проверяемый источник»; слепая зона чиста (0 вхождений) |
| 3 | FR-168: `cover` — негативная пометка вместо позитивной документации | **accepted-deviation** | BR-015 самого требования: движок выше docs; engine-проб Q4 — атрибута в движке на пине нет; AC-082 остаётся зелёным, факт остаётся engine-истинным; пересмотр — при новом engine-окне (жизненный цикл требования) |
| 4 | После записи этого файла `check.sh --fast` и ac-096 краснеют ровно на одну собственную C1 (файл не в `acceptance/_index.md`); красный старт TDD-цепочки воспроизведён QA архивом `c255f98` (22 контентных красных + warden) | **env** (не дефект) | Таксономия QA-отчёта; условие снятия — центральная PM-регистрация (прецедент: plantuml-приёмка зарегистрирована тем же механизмом, `ee271f9`) |
| 5 | (из QA, перенос) C6 валидатора контента стал no-op для `docs/` после миграции ключа (`scripts/validate-content.py:123-125` читает `filterProperties`) | **follow-up, вне среза writer** | Зона валидатора — параллельный поток; кандидат: читать engine-форму `filterProperty` (матч `id ?? name`). На AC/FR этой приёмки не влияет | 

**Дефекты:** не обнаружены. Ни одно отклонение не нарушает ни одного AC, ни FR-161…FR-182, ни
BR-015 (четыре переигрывания выполнены буквально — негативные контролы зелёные), ни BR-016
(`<gallery>`/`Gantt` отсутствуют), ни BR-017 (правило ссылок не тронуто), ни BR-018 (guardrails
служебных зон в носителе).

---

## Гейты приёмки

| Гейт | Результат |
|---|---|
| Backlog-closure | `✓ n/a` — `scripts/check-backlog-closure.py` в дереве отсутствует |
| Breaking-change-guide | `✓ n/a` — `scripts/check-breaking-change-section.py` в дереве отсутствует; по существу изменение аддитивно (Minor-ожидание, NFR-071; semver — решение PM при выпуске), breaking-обещаний не вносит |
| Downstream-test-touch | `N/A` — окно коммитов волны `c255f98^..03011ee` трогает в `tests/` только собственную suite `writer-sync-470` и регистрирует шаг 15 в `scripts/check-gramax.sh` (--full only, рекурсии с `--fast` нет); ни один тест закрытых эпиков не сужен (собственный `git diff --name-only`); соседние suite зелёные — QA 101/101 по восьми соседям, собственный спот-чек BA plugin-contract 7/7 |

Вердикт по правилу: каждый AC покрыт (24/24), тесты зелёные (собственный прогон suite 24/24 rc=0;
дословные формулы AC-073…AC-095 — 23/23 PASS собственным исполнением; композит AC-096 rc=0 на
вердиктном состоянии), гейты pass/`n/a` — **pass**.

## Действия вне гейта (не блокеры вердикта)

1. **PM:** регистрация QA-отчёта и этого протокола в `docs/60-implementation/acceptance/_index.md`
   — снимает обе текущие own-file C1 гейта (возвращает ac-096/ac-050-composite в зелёный).
2. **PM/Tech-writer до release:** запись `Contract:` в `plugins/gramax/CHANGELOG.md` (диф тегов
   9+4, schemaVersion 2 — NFR-072) + bump `plugin.json`/`marketplace.json` 4.6.0 → 4.7.0.
3. **Follow-up (вне среза writer):** адаптация C6 `scripts/validate-content.py` к engine-форме
   `filterProperty` — зона потока валидаторов/SA.
4. **pm-review/следующее окно движка:** GES-поверхность (`showIf`, `mode`, `shuffleQuestions`,
   9 типов) — верификация при доступных исходниках; пересмотр BR-016 (`<gallery>`/`Gantt`) и
   вне-enum палитры — при новом окне (жизненный цикл требования).

## Инварианты и Safeguards (контроль исполнения)

Содержательные инварианты требования проверены: четыре переигрывания BR-015 — буквально
(раздел override'ов); ни одно валидное правило 4.6.0 не объявлено невалидным без engine-вердикта
(legacy-пометки на месте — NFR-071); источники у новых утверждений присутствуют (RES-007 §-строки,
вердикты RES-008, engine `путь:строка` — Q1-проб дизайна); документация и контракт тегов синхронны
(NFR-072); служебные зоны защищены до прочих правок (Guardrails SKILL.md — BR-018).
**Sensitive content:** N/A — документация синтаксиса публичного продукта, PII/секретов нет.

---

## VERDICT

**accept** — 24/24 AC pass (собственные прогоны: suite 24/24 rc=0; дословные формулы
AC-073…AC-095 — 23/23 PASS собственной рукой; warden AC-079 — собственные счётчики 0/0; композит
AC-096 — rc=0 на вердиктном состоянии, последующая красная — собственная C1 этого файла, env,
снятие PM-регистрацией), 22/22 FR implemented, 0 partial, 0 none. Четыре override'а RES-008
подтверждены собственными грепами по всему дереву writer (0 литеральных форм `<gallery`/
`display="Gantt"`/`{scale`/`cover=`), диф `gramax-tags.json` — точное соответствие контракту
NFR-072 (собственный diff: 9+4, schemaVersion 2, snippet/diagramTags не тронуты), миграция
`docs/.doc-root.yaml` подтверждена собственным diff. Дефералы (CHANGELOG `Contract:`, bump
версии, композитная обусловленность) и ревью-пункты (слепая зона `{scale=…}` — чиста, GES-строки,
`cover`-амбивалентность) записаны с владельцами и классифицированы accepted-deviation — ни одно
не засчитано как pass. Дефектов нет; блокеров нет.

**Передача:** волна 4.7.0 собрана — Tech-writer (release-flow: CHANGELOG `Contract:`, bump) →
`pm-review`. Код, тесты и контент навыка этой приёмкой не менялись; единственный артефакт
сессии — этот протокол.
