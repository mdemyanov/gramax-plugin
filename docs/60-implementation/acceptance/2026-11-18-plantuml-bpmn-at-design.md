---
title: "Приёмка (BA-acceptance): Авторство PlantUML/BPMN-диаграмм — навык plantuml: file-based, без конвертационных пайплайнов"
order: 12
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# Приёмка (BA-acceptance): Авторство PlantUML/BPMN-диаграмм — навык plantuml: file-based, без конвертационных пайплайнов

**Опоры:** `docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md`,
`docs/00-project/adr/0023-plantuml-bpmn-skill.md`,
`docs/40-architecture/2026-11-18-plantuml-bpmn-design.md`, `tests/gramax/plantuml-bpmn/README.md`,
`plugins/gramax/skills/plantuml/SKILL.md`

**Роль:** BA-acceptance gate — проверка AC-051…AC-062 и FR-141…FR-148 требования против
**реализованного** навыка и граничных правок mermaid/drawio (не против обещаний дизайна),
с независимым повторным исполнением буквальных проверок и вердиктом.
**Дата приёмки:** 2026-11-18
**Требование:** [Авторство PlantUML/BPMN-диаграмм в Gramax (file-based, без конвертационных пайплайнов)](../../30-requirements/2026-11-18-plantuml-bpmn-requirement.md) (AC-051…AC-062, FR-141…FR-148)
**ADR:** [0023-plantuml-bpmn-skill](../../00-project/adr/0023-plantuml-bpmn-skill.md) (плейсмент — Решение 1, релизная поверхность — Решение 2, контракт тегов/verify-before-include — Решение 3, file-based канон — Решение 4)
**Дизайн:** [2026-11-18-plantuml-bpmn-design](../../40-architecture/2026-11-18-plantuml-bpmn-design.md) (план файлов, пин-тексты триггеров, контракт тегов, стоп-правило, тест-хуки)
**Реализация:** `plugins/gramax/skills/plantuml/SKILL.md` (134 строки) + `references/plantuml-syntax.md` (210 строк) + граничные правки `plugins/gramax/skills/mermaid/SKILL.md` (9 строк: description + 4-опционный fallback) и `plugins/gramax/skills/drawio/SKILL.md` (4 строки: BPMN выведен с указателем) — коммит `4758311`; footprint ровно план файлов дизайна, `plugins/gramax/scripts/` не тронут (BR-008)
**QA-отчёт:** [QA Report — навык plantuml](../test-reports/2026-11-18-plantuml-bpmn-qa-report.md) — независимый прогон, рекомендация **accept** (принята как вход, не как замена собственной проверке)
**Suite:** `tests/gramax/plantuml-bpmn/` (12 stub'ов + fixtures/doc-root, ADR-0011)
**Метод:** каждый AC — проверка из требования, свидетельство реализации (файл:строка или grep), собственный дословный прогон команды AC, вердикт PASS/FAIL. Каждый FR — implemented / partial / none со свидетельством. Не-покрытия записываются как not-covered-with-owner, никогда как pass. Отклонения дизайн↔реализация классифицируются: accepted-deviation (с основанием) или дефект.

---

## Summary

| Метрика | Значение |
|---|---|
| AC | **12 pass / 0 fail** (AC-051…AC-062) |
| FR | **8 implemented / 0 partial / 0 none** (FR-141…FR-148) |
| NFR | NFR-059/060/062/063 satisfied; NFR-061 — контрактная половина satisfied, живой смоук not-covered; NFR-064 — satisfied по вердиктному состоянию (хронология гейта — «Находки» №1) |
| Не-покрытия | 3 (живые половины AC → pm-review; релизные runtime-probe `<bpmn>`/Salt → PM; semver-bump → Tech-writer) — все с владельцами, деферал признан accepted-deviation |
| Отклонения | 3 accepted-deviation + 1 cosmetic, 0 дефектов (развод — раздел «Находки») |
| Гейты | Backlog-closure `✓ n/a`; Breaking-change-guide `✓ n/a`; Downstream-test-touch `N/A` |
| Вердикт | **accept** (блокеров нет; список неблокирующих действий PM/Tech-writer — в конце) |

Собственные прогоны BA на момент приёмки: `bash tests/gramax/plantuml-bpmn/run.sh` →
`All 12 AC tests passed.` (rc=0); дословные warden-проверки — AC-057 счётчик `0`,
AC-059 литералы `0`, AC-058 — ключи в 4 файлах дерева навыков, все 9 ключей FR-146 в
description; пин-сверка — description plantuml **побайтно равен** пин-тексту дизайна
(программное сравнение), все пять строк fallback-диалога mermaid совпадают с пином.
Хронология композитного гейта: во время suite-прогона гейт зелёный (внутренний
`check.sh --fast` stub'а ac-062 прошёл); в ходе сессии приёмки (15:04) в дерево лёг
незатреканный приёмочный файл параллельного validators-потока — гейт покраснел ровно на
одну чужую C1; предмет plantuml ни в одном прогоне гейта не указан. Детали — «Находки» №1.

---

## AC coverage (AC-051…AC-062)

Каждый AC закрыт ровно одним stub'ом suite (карта — `tests/gramax/plantuml-bpmn/README.md`);
уровни: AC-051…AC-061 integration, AC-062 e2e — как предписано дизайном (§«Контракт с
QA-author»). У навыка нет исполняемой точки входа (BR-008 запрещает скрипт-эмулятор),
поэтому suite несёт контрактные половины + механику на фикстурах; артефактные половины
живой сессии — в разделе «Не-покрытия» с владельцем. Ниже — вердикт BA по каждому AC;
колонка «Прогон BA» — моё собственное исполнение, не пересказ QA-отчёта.

| AC | Проверка из требования (предмет) | Свидетельство реализации | Прогон BA | Вердикт |
|---|---|---|---|---|
| AC-051 (FR-141/147) | `.puml` создан рядом со статьёй: `test -f <dir>/<page-slug>-<diagram-slug>.puml` | Workflow `SKILL.md:20-27` (Write в директории `target_page` — `:25`, не в assets); naming convention `:82-106`; фикстуры `fixtures/doc-root/` на месте; stub `ac-051` PASS | контрактная половина + фикстуры — OK; артефактная половина живой сессии — not-covered (№1) | **PASS** |
| AC-052 (FR-141) | `.puml` — чистый PlantUML: `head -1 \| grep '^@start'` + нет `<plant-uml`/` ```plant-uml ` | Контракт чистоты `SKILL.md:31` («только DSL, без разметки и обёрток») + `references/plantuml-syntax.md:17-19`; stub исполнил литералы на фикстуре `overview-component-diagram.puml` — PASS | литеральная механика на фикстуре — OK (первая строка `@startuml`, разметки нет — проверено чтением фикстуры) | **PASS** |
| AC-053 (FR-144) | статья содержит `<plant-uml path="./` | Каноническая форма `SKILL.md:26,67-79` (самозакрывающийся, пустые строки, атрибуты только по явному запросу, негатив на mermaid-дефолты 800px/450px — `:79`); stub `ac-053` PASS | контракт формы тега — OK | **PASS** |
| AC-054 (FR-142) | Salt тем же контуром: `grep '@startsalt' <file>.puml` | Секция Salt `SKILL.md:45-53` (`@startsalt`/`@endsalt` в тот же `.puml`, штатный тег, «отдельного механизма нет») + нотация в references `:108-127`; stub `ac-054` PASS | Salt-контур — OK | **PASS** |
| AC-055 (FR-143) | `.bpmn` — Camunda XML: `head -1 \| grep '<?xml'` + `bpmn:definitions\|<definitions` | Секция BPMN `SKILL.md:55-61` (только файловая форма; inline не выдумывается — `:57`) + каркас XML `references/plantuml-syntax.md:129-193`; stub исполнил литералы на синтетическом Camunda XML — PASS | контракт + механика — OK | **PASS** |
| AC-056 (FR-143) | статья содержит `<bpmn path="./` | Тег `SKILL.md:73-80` (самозакрывающийся, только `path` — `:80`, verify-оговорка `:61`); stub `ac-056` PASS | контракт тега — OK | **PASS** |
| AC-057 (NFR-060, BR-008) | в `plugins/gramax/scripts/` нет plantuml/bpmn-скриптов | «Стоп-правило» `SKILL.md:128-130` — дословно по пину дизайна (запрет SVG/PNG-конвертаций и локальных рендеров, эскалация SA/PM, анти-ADR-0008) + BR-009 «единственные артефакты — исходник и тег»; `git show --stat 4758311` — scripts/ не тронут | **дословный прогон BA**: `ls plugins/gramax/scripts/ \| grep -icE 'plantuml\|plant-uml\|bpmn'` → **0** | **PASS** |
| AC-058 (FR-146) | в дереве навыков есть явные plantuml/bpmn-триггерные ключи | description plantuml `SKILL.md:3`; BPMN выведен из «подходит»-строки drawio (`drawio/SKILL.md:65`) | **дословный прогон BA**: `grep -rliE 'plant-uml\|plantuml\|bpmn' plugins/gramax/skills/` → 4 файла (plantuml×2, mermaid, drawio); все 9 ключей FR-146 в description — поимённо | **PASS** |
| AC-059 (FR-146, BR-011) | mermaid не взял plantuml/bpmn-авторство: `grep -icE '@startuml\|\.bpmn' mermaid/SKILL.md` = 0 | 4-опционный fallback `mermaid/SKILL.md:24-31` построчно = пину; дефолт «**mermaid**» и узкий контракт «Только для диаграмм в синтаксисе Mermaid DSL» сохранены (`:3,31`); анти-триггер «НЕ для PlantUML/BPMN → gramax:plantuml» (`:3`); правило делегации `:33-36` | **дословный прогон BA**: счётчик литералов → **0**; пин-сверка 5 строк fallback — совпадение | **PASS** |
| AC-060 (NFR-061, FR-148, smoke) | повторный вызов, ответ «нет» → `.puml`/`.bpmn` неизменен, diff пуст | Алгоритм коллизии `SKILL.md:23` (первые 5 строк → показать → перезаписать/другое имя/отмена, «Без явного „перезаписать“ — не трогай файл»); фикстура коллизии на месте; stub `ac-060` PASS | контрактная половина — OK; живой смоук — not-covered (№2) | **PASS** |
| AC-061 (FR-145, BR-010, smoke) | inline ` ```plant-uml ` не переписывается молча, diff пуст | Секция «Backward compatibility» `SKILL.md:108-122` (распознавание, уведомление, миграция по подтверждению, опции 1:1 `title/scale/float` — `:118`, «Без явного подтверждения — файл не трогать» — `:122`); фикстура `legacy-inline.md` с опциями; stub `ac-061` PASS | контрактная половина — OK; живой смоук — not-covered (№2) | **PASS** |
| AC-062 (NFR-064) | `bash scripts/check.sh --fast` → exit=0 | stub `ac-062` (e2e) PASS в suite-прогоне BA — внутренний гейт зелёный, rc=0 | вердиктное состояние — rc=0; повтор BA в ходе сессии — rc=1 на **одной чужой C1** (validators-поток, 15:04) — env, «Находки» №1; на предмет plantuml не указывает | **PASS** |

Дополнительно к формуле требования (собственная проверка BA): пин-контракты дизайна
подтверждены — description plantuml побайтно равен YAML-пину дизайна; стоп-правило BR-008,
verify-оговорка `<bpmn>` (`SKILL.md:61`), оговорка окружения `DIAGRAM_RENDERER_SERVICE_URL`
(`:124-126`), naming-таблица примеров (`:100-106`) — воспроизведены дословным смыслом пина;
`<bpmn>`-атрибуты не домыслены (только `path` — `:80`); дефолтных размеров нет («пустое поле
лучше правдоподобного» — `:79`). Регрессия mermaid-контракта исключена: `mermaid-adoption`
10/10 в QA-прогоне, правки mermaid — только description + fallback (9 строк).

---

## Не-покрытия (not-covered-with-owner — никогда не pass)

| # | Что именно | Почему не исполняемо здесь | Владелец | Классификация деферала |
|---|---|---|---|---|
| 1 | Артефактные половины AC-051…AC-056 — файлы и теги, созданные живой сессией авторства | У навыка нет исполняемой точки входа; скрипт-эмулятор запрещён BR-008; живой канал в брифе приёмки не выдан | `pm-review` (прецедент — houses-смоки mermaid, ADR-0010) | **accepted-deviation** — таксономия suite зафиксирована на этапе QA-author (`README.md` «Границы»); все автоматизируемые половины автоматизированы и зелёные; поведенческая верификация — штатный шаг pm-review, не лазейка |
| 2 | Поведенческие смоки AC-060/AC-061 — diff до/после в живой сессии | То же: действия агента в живой сессии; контрактные половины зелёные | `pm-review` (бриф прямо назначает not-covered) | **accepted-deviation** — та же механика; запрет молчаливой мутации продублирован в тексте навыка дважды (`SKILL.md:23,122`) |
| 3 | Релизные runtime-probe рендера `<bpmn>` и Salt в живом окружении (`DIAGRAM_RENDERER_SERVICE_URL`) | Окружение внешнее по отношению к репозиторию — из дерева не измеримо (дизайн «Открытые вопросы» п.2; ADR-0023 Решение 3 — verify-before-include) | Релизный чек-лист PM **до публичного обещания рендера** (CHANGELOG-запись обязана нести оговорку); при неудаче — эскалация PM (оговорка-навсегда vs дескоп FR-143), конвертационный pipeline исключён в любом исходе (BR-008) | **accepted-deviation** — решение закреплено в ADR-0023 до реализации; деферал не снимает verify-оговорку из навыка (`SKILL.md:61`) |

Semver-bump `plugin.json`/`marketplace.json` (Q-3) — не AC и не FR, четвёртое not-covered
QA-отчёта: подтверждено собственным прогоном BA — оба файла в 4.6.0, CHANGELOG без записи
(классификация — «Находки» №3).

---

## FR coverage (FR-141…FR-148)

| FR | Требование (кратко) | Реализация | Статус |
|---|---|---|---|
| FR-141 | PlantUML DSL в `.puml` рядом со статьёй + `<plant-uml path="./…"/>`; чистый `@startuml`/`@enduml` | Workflow `SKILL.md:20-27` (Write `:25`, Edit `:26`); секция PlantUML `:29-43` («только DSL, без Gramax-разметки и обёрток» — `:31`); справочник типов `references/plantuml-syntax.md:23-106` | **implemented** |
| FR-142 | Salt тем же контуром, без отдельного механизма | `SKILL.md:45-53` — `@startsalt`/`@endsalt` в тот же `.puml`, штатный тег; нотация и элементы — `references/plantuml-syntax.md:108-127`; оговорка окружения — `SKILL.md:124-126` | **implemented** |
| FR-143 | `.bpmn` (Camunda XML) + `<bpmn path="./…"/>`; только файловая форма | `SKILL.md:55-61` («inline-вариант… не существует и не выдумывается» — `:57`); каркас XML с `bpmndi` — `references/plantuml-syntax.md:129-193`; verify-оговорка и указатель на релизный probe — `:61` | **implemented** |
| FR-144 | теги самозакрывающиеся, пустая строка до/после; атрибуты сверх `path` только по ground truth | `SKILL.md:63-80`: `/>` и пустые строки — `:77`; атрибуты `<plant-uml>` ровно схема движка (`title/width/height/float/scale`, «только по явному запросу») — `:79`; `<bpmn>` только `path`, «не домысливаются» — `:80`; дефолтных размеров нет | **implemented** |
| FR-145 | inline ` ```plant-uml ` распознаётся, пользователь оповещён, действие по политике; молчаливая перезапись запрещена | `SKILL.md:108-122` — политика Q-2(i) дизайна: уведомление + предложение точечной миграции `<page-slug>-existing.puml`, опции блока → атрибуты тега 1:1 (`:118`); «не выполняет миграцию молча» — `:122`; batch вне scope — `:122` | **implemented** |
| FR-146 | триггерные ключи у владельца; mermaid сохраняет узкий контракт; fallback расширен, дефолт — решение SA | description plantuml — все 9 ключей («plantuml», «plant-uml», «puml», «UML-диаграмма», «Salt», «макет интерфейса», «bpmn», «BPMN-процесс», «Camunda») + взаимные анти-триггеры (`SKILL.md:3,16`); mermaid — fallback 4 опции (`mermaid/SKILL.md:24-31`, построчно = пину), дефолт «**mermaid**» (`:31`), узкий контракт сохранён (`:3`), делегация plantuml/bpmn → `gramax:plantuml` (`:33-36`); drawio — BPMN выведен из «подходит»-строки с указателем (`drawio/SKILL.md:65`), анти-триггер в description (`:3`); дефолт неявного запроса — mermaid без изменений (ADR-0023 Решение 1) | **implemented** |
| FR-147 | `<page-slug>-<diagram-slug>.puml/.bpmn`; конвенция единая с mermaid, второй нет | `SKILL.md:82-106` — дословная инстанциация ADR-0010 Решение 2: `_index.md` → имя родителя (`:89`), kebab-case ASCII ≤30 с обрезкой по целым словам (`:95`), fallback `diagram` (`:96`), кириллица → перевод/ввод без автотранслитерации (`:97`), запрещённые символы → `-` (`:98`); «второй параллельной конвенции нет» — `:84` | **implemented** |
| FR-148 | при коллизии — показать начало, спросить; без явного «перезаписать» файл не трогается | `SKILL.md:23` — первые 5 строк → показать → три опции → «Без явного „перезаписать“ — не трогай файл»; фиксирующий текст повторён в section Backward compatibility `:122` | **implemented** |

## NFR (краткий разбор)

- **NFR-059 (без внешних зависимостей)** — satisfied: «без MCP, без скриптов, без preview,
  без внешних инструментов: только Write/Edit/Read» (`SKILL.md:8`) — контраст с
  drawio-workflow сохранён.
- **NFR-060 (без скриптов)** — satisfied: дословный прогон AC-057 — счётчик 0;
  `plugins/gramax/scripts/` не тронут footprint'ом Dev (BR-008 по построению).
- **NFR-061 (идемпотентность)** — контрактная половина satisfied (`SKILL.md:23,122`);
  поведенческая — not-covered №2, владелец pm-review.
- **NFR-062 (токен-бюджет)** — satisfied: ядро 134 строки, справочник 210 строк в
  `references/`, «загружается при затруднениях, не при каждом вызове» (`SKILL.md:134`)
  — прецедент mermaid NFR-004 воспроизведён.
- **NFR-063 (портируемость)** — satisfied: ASCII kebab-case, кириллица → семантический
  перевод или ручной ввод (`SKILL.md:95-98`).
- **NFR-064 (гейт)** — satisfied по вердиктному состоянию (suite-прогон BA: rc=0,
  `All 12 AC tests passed.`); последующая красная — чужая C1 validators-потока (env),
  не свойство реализации («Находки» №1).

---

## Находки: отклонения дизайн↔реализация

| # | Находка | Классификация | Основание |
|---|---|---|---|
| 1 | Композитный гейт покраснел в ходе сессии приёмки: `bash scripts/check.sh --fast` → rc=1, `Errors: 1` — C1 на `docs/60-implementation/acceptance/2026-11-18-validators-parity-at-design.md` (файл параллельного validators-потока, появился 15:04, незатреканный, в `acceptance/_index.md` не зарегистрирован). Вердиктный suite-прогон BA минутами ранее — 12/12 при зелёном внутреннем гейте | **env** (не дефект, не регрессия) | Таксономия QA-отчёта: не regression — контентные AC-051…061 зелёные во всех прогонах, краснел только ассерт «гейт обязан быть 0»; не new-продукта — отказ создан артефактом чужого потока, код plantuml между прогонами не менялся (`git status` — файл untracked); условие снятия — центральная PM-регистрация (прецедент исполнен дважды за день: export-файл в 14:48, QA-отчёты в `4109b8c`/`4ba3202`). Собственный файл этой приёмки добавит ровно одну ожидаемую own-file C1 — снятие тем же механизмом |
| 2 | Дублирование drawio-демаркации в description mermaid: «…SVG-схем через drawio — используй gramax:drawio. Для drawio → gramax:drawio.» (подтверждено grep'ом BA) | **cosmetic** (release-pass, не дефект) | Оба указателя ведут в одну цель — контракт триггеров не ослаблен; AC-059 не затронуто (грепаются литералы `@startuml`/`.bpmn`, не drawio-упоминания); пин дизайна фиксировал только анти-триггер PlantUML/BPMN и fallback-текст — description-редактура mermaid была отступлена Dev. Кандидат на правку Tech-writer'ом в release-pass (тот же вывод QA-отчёта — принят) |
| 3 | Релизная поверхность не исполнена: `plugin.json` 4.6.0, `marketplace.json` 4.6.0, CHANGELOG без записи, description entry без plantuml | **accepted-deviation** | Последовательность ADR-0023 Решение 2: bump делает Tech-writer в release-flow **после** BA-acceptance и зелёного QA-runner — состояние плановое, вне AC-051…062. Действие Tech-writer/PM — «Действия вне гейта» |
| 4 | README suite (`tests/gramax/plantuml-bpmn/README.md`) несёт устаревший статус «красный по замыслу — реализация ещё не создана» | **cosmetic** (наследовано из QA-отчёта) | Описывает состояние QA-author на `9355b69`; снято реализацией `4758311` (12/12). Карта AC → stub актуальна; на гейты не влияет; правка — косметика документации suite вне периметра этой приёмки |

**Дефекты:** не обнаружены. Ни одно отклонение не нарушает ни одного AC, ни FR-141…FR-148,
ни BR-008 (конвертационный pipeline не построен — стоп-правило в носителе дословно),
ни BR-009 (артефакты — только исходник и тег), ни BR-010 (запрет молчаливых мутаций
продублирован), ни BR-011 (mermaid-контракт: 10/10 mermaid-adoption, правки только
триггерные формулировки).

---

## Гейты приёмки

| Гейт | Результат |
|---|---|
| Backlog-closure | `✓ n/a` — `scripts/check-backlog-closure.py` в дереве отсутствует |
| Breaking-change-guide | `✓ n/a` — `scripts/check-breaking-change-section.py` в дереве отсутствует; по существу изменение additive minor (ADR-0023 Решение 2) — breaking-обещаний не вносит |
| Downstream-test-touch | `N/A` — тесты закрытых эпиков окном волны не тронуты: `git diff --name-only 99201c0^..HEAD -- tests/gramax/{mermaid-adoption,writer-consumer-rules,plugin-contract,export-skill}` пуст; изменения в `tests/` — собственные stub'ы этого потока (`plantuml-bpmn`) и новая suite параллельного validators-потока (`catalog-validator`) |

Вердикт по правилу: каждый AC покрыт (12/12), тесты зелёные (собственный прогон suite 12/12,
rc=0; дословные warden-прогоны AC-057/058/059 — 0/9-ключей/0), гейты pass/`n/a` — **pass**.

---

## Действия вне гейта (не блокеры вердикта)

1. **PM:** регистрация этого протокола и приёмочного файла validators-потока в
   `docs/60-implementation/acceptance/_index.md` (снимает обе текущие C1 гейта);
   релизный runtime-probe `<bpmn>`/Salt в живом окружении — до публичного обещания рендера
   (не-покрытие №3); при неудаче probe — решение оговорка-навсегда vs дескоп FR-143.
2. **Tech-writer (release-flow, ADR-0023 Решение 2):** bump `plugin.json` + `marketplace.json`
   одним коммитом, description entry с упоминанием plantuml (PlantUML/Salt/BPMN),
   CHANGELOG-запись с оговоркой окружения рендера и verify-статусом `<bpmn>`;
   по усмотрению — косметическая правка дублированной drawio-демаркации в description
   mermaid (находка №2).
3. **pm-review:** живые половины AC-051…056 и смоки AC-060/061 (не-покрытия №1–2) —
   поведенческая верификация навыка в живой сессии.
4. **Косметика документации suite:** актуализация статуса в
   `tests/gramax/plantuml-bpmn/README.md` (находка №4).

---

## VERDICT

**accept** — 12/12 AC pass (собственные прогоны: suite 12/12 rc=0; дословные warden-проверки
AC-057 = 0 скриптов, AC-059 = 0 литералов в mermaid, AC-058 = 4 файла с ключами и все
9 ключей FR-146; композитный гейт на вердиктном состоянии rc=0, последующая красная —
чужая C1 validators-потока, класс env с исполнимым условием снятия), 8/8 FR implemented,
0 partial, 0 none. Пин-контракты дизайна подтверждены сверх формулы требования: description
plantuml побайтно равен пину, fallback mermaid построчно равен пину, BPMN выведен из
«подходит»-строки drawio, стоп-правило BR-008 воспроизведено дословно. Не-покрытия
(живые половины AC, смоки, релизные probe, semver-bump) записаны с владельцами и
классифицированы accepted-deviation — ни одно не засчитано как pass. Дефектов нет;
блокеров нет.
