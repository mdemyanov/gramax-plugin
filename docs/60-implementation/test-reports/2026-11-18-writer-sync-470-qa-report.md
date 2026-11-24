---
title: "QA Report — синхронизация writer 4.7.0 с движком 48592b36 (AC-073…AC-096: четыре override'а RES-008, диф контракта тегов NFR-072, миграция filterProperty)"
order: 15
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# QA Report — синхронизация writer 4.7.0 с движком 48592b36 (AC-073…AC-096: четыре override'а RES-008, диф контракта тегов NFR-072, миграция filterProperty)

**Опоры:** `tests/gramax/writer-sync-470/README.md`,
`docs/30-requirements/2026-11-18-writer-sync-470-requirement.md`,
`docs/40-architecture/2026-11-18-writer-sync-design.md`

| Поле | Значение |
|---|---|
| **Дата прогона** | 2026-11-18 |
| **Ветка/дерево** | `main`, HEAD `03011ee` (коммит Dev потока; red-phase — `c255f98`, дизайн — `a59db10`); дерево чистое, единственный незатреканный путь — `.zcode/` (среда агента) |
| **Tester** | QA-runner — независимая верификация: suite исполнен собственной рукой, отчёт Dev не пересказывался; контракты сверены собственными grep/diff, а не стабами |
| **Требование** | [writer 4.7.0 — массовая синхронизация скилла](../../30-requirements/2026-11-18-writer-sync-470-requirement.md) (FR-161…FR-182, AC-073…AC-096) |
| **Дизайн** | [2026-11-18-writer-sync-design.md](../../40-architecture/2026-11-18-writer-sync-design.md) (Q1–Q6, четыре override'а RES-008, контракт тегов NFR-072) |
| **Suite приёмки** | `tests/gramax/writer-sync-470/` — 24 скрипта, один-к-одному на AC-073…AC-096; AC-079 — warden негатива, AC-096 — композитный гейт |
| **Опоры** | [README suite](../../../tests/gramax/writer-sync-470/README.md), требование, дизайн (ссылки в строках выше) |

---

## Summary

| Suite/проверка | Команда | Passed | Failed | Exit | Время |
|---|---|---|---|---|---|
| **writer-sync-470** (приёмка AC-073…096) | `bash tests/gramax/writer-sync-470/run.sh` | **24** | **0** | `0` | ≈6.6 c |
| writer-consumer-rules | `bash tests/gramax/writer-consumer-rules/run.sh` | 11 | 0 | `0` | ≈1.0 c |
| link-form-resolver | `bash tests/gramax/link-form-resolver/run.sh` | 8 | 0 | `0` | ≈1.4 c |
| link-form-migration | `bash tests/gramax/link-form-migration/run.sh` | 7 | 0 | `0` | ≈1.3 c |
| mermaid-adoption | `bash tests/gramax/mermaid-adoption/run.sh` | 10 | 0 | `0` | ≈4.1 c |
| plantuml-bpmn | `bash tests/gramax/plantuml-bpmn/run.sh` | 12 | 0 | `0` | ≈5.8 c |
| export-skill | `bash tests/gramax/export-skill/run.sh` | 10 | 0 | `0` | ≈5.2 c |
| catalog-validator | `bash tests/gramax/catalog-validator/run.sh` | 36 | 0 | `0` | ≈12.9 c |
| plugin-contract | `bash tests/gramax/plugin-contract/run.sh` | 7 | 0 | `0` | ≈0.6 c |
| Композит `check.sh --fast` (AC-096) | `bash scripts/check.sh --fast` | — | — | `0`, `Errors: 0 \| Warnings: 6` | ≈4.5 c |
| **Итого (bash-наборы)** | | **125** | **0** | — | — |

- **passed:** 125/125 (24 приёмочных + 101 регрессионных соседних); поверх — все 24 дословные формулы AC из требования исполнены отдельно, все PASS (см. «AC coverage»).
- **failed:** 0. Классификация отказов: regression — 0, new — 0, flaky — 0, env — 0 (в дереве на момент вердикта; ожидаемая собственная C1 после записи этого отчёта — см. «Постпроверка»).
- **Итог одной строкой:** приёмочный suite зелёный при независимом прогоне (24/24), красный старт TDD-цепочки воспроизведён архивом `c255f98` (22 контентных красных + warden — в точности по README suite), четыре override'а RES-008 и диф контракта тегов подтверждены собственными grep/diff по всему дереву writer, миграция `docs/.doc-root.yaml` подтверждена. Рекомендация — **accept**.

---

## AC coverage (AC-073…AC-096)

Каждый AC закрыт ровно одним скриптом suite (`ac-073`…`ac-096`, соответствие 1:1 по README). Дополнительно к suite исполнена дословная команда из раздела Acceptance Criteria требования (авторитетный раннер bash-suite — `run.sh`; pytest по `.sh` не собирает ни одного теста — известная особенность прибора, не дефект).

| AC | Скрипт | Suite | Дословная формула требования | Независимый результат |
|---|---|---|---|---|
| AC-073 | `ac-073-searchphrases-frontmatter.sh` | PASS | grep `searchPhrases` по SKILL.md + references | PASS |
| AC-074 | `ac-074-aliases-frontmatter.sh` | PASS | grep `aliases` по SKILL.md + references | PASS |
| AC-075 | `ac-075-quizzes-reference.sh` | PASS | файл `quizzes.md` + `questionAnswer`/`showIf`/`countOfCorrectAnswers` | PASS |
| AC-076 | `ac-076-quiz-twelve-types.sh` | PASS | `ranking` + `matrix` в quizzes.md | PASS |
| AC-077 | `ac-077-cut-property-inline-property.sh` | PASS | `<cut`/`<property`/`<inline-property` в blocks.md | PASS |
| AC-078 | `ac-078-view-defs-hiding-rewrite.sh` | PASS | `orderby` + `Kanban` + «скрыт» в blocks.md | PASS |
| AC-079 | `ac-079-no-gallery-no-gantt.sh` (warden) | PASS | `! grep '<gallery'` + `! grep 'display="Gantt"'` | PASS — 0 вхождений обеих форм |
| AC-080 | `ac-080-cmd-kbd-xml-forms.sh` | PASS | `<cmd text=`/`<kbd text=`/`[cmd:` в blocks.md | PASS |
| AC-081 | `ac-081-image-scale-size-semantics.sh` | PASS | `scale=` + «реальный размер» в blocks.md | PASS |
| AC-082 | `ac-082-video-hostings-cover-negative.sh` | PASS | `dropbox` + `mega` + `cover` в blocks.md | PASS |
| AC-083 | `ac-083-openapi-showschemas-showinfo.sh` | PASS | `showSchemas` + `showInfo` в blocks.md | PASS |
| AC-084 | `ac-084-code-block-section.sh` | PASS | «блок кода» + `highlight.js` в blocks.md | PASS |
| AC-085 | `ac-085-heading-anchors.sh` | PASS | `{#` в blocks.md | PASS |
| AC-086 | `ac-086-fragment-canonical-legacy.sh` | PASS | `<fragment id=`/`fragment-link`/`legacy` + «фрагмент» в SKILL.md | PASS |
| AC-087 | `ac-087-link-md-caveat-rule-preserved.sh` | PASS | «без .md» + одна из трёх фраз оговорки в SKILL.md | PASS — «обе формы резолвятся» (SKILL.md:231) |
| AC-088 | `ac-088-doc-root-new-keys.sh` | PASS | `logo_dark`/`relatedLinks`/`versions`/`hidden` + regex `filterProperty([^i]|$)` | PASS |
| AC-089 | `ac-089-syntax-enum-style-palette.sh` | PASS | `GitHub Flavored Markdown` + `blue-pink\|orange-red` | PASS |
| AC-090 | `ac-090-gramax-views-storage.sh` | PASS | `.gramax/views` в дереве writer | PASS |
| AC-091 | `ac-091-lfs-gitattributes.sh` | PASS | `lfs` + `.gitattributes` в doc-root-schema.md | PASS |
| AC-092 | `ac-092-multilanguage-rules.sh` | PASS | «мультиязыч» + «непереведён» в references | PASS |
| AC-093 | `ac-093-property-types-engine-names.sh` | PASS | `docportalVisible` + `\bFlag\b` + `\bNumeric\b` | PASS |
| AC-094 | `ac-094-icons-folder.sh` | PASS | `.icons/` в дереве writer | PASS |
| AC-095 | `ac-095-guardrails-template-inbox-mr.sh` | PASS | `template:`/`.gramax/templates`/`.gramax/inbox`/`.gramax/mr` в SKILL.md | PASS |
| AC-096 | `ac-096-composite-check-fast.sh` | PASS | `bash scripts/check.sh --fast && echo PASS` | PASS — `rc=0`, `Errors: 0 \| Warnings: 6` |

Пропусков нет; все 24 скрипта исполнены и отдельно, и агрегатором.

---

## Воспроизведение красного старта (проверка TDD-цепочки)

Архив `c255f98` (red-phase коммит: suite + дизайн, реализации нет) развёрнут в `/tmp/w470-red-check`, `git init` для резолва `rev-parse`, прогон suite:

```text
Passed: 1  /  Failed: 23
  зелёный — только warden ac-079 (негатив <gallery>/Gantt: форм нет и до реализации)
  красные — все 22 контентных AC (ac-073…ac-078, ac-080…ac-095) — в точности таблица «Стартовое состояние» README
  ac-096 — красный В САNDВОКСЕ архива: fresh `git init` без core.hooksPath (check-hooks-path FAILED)
           и пустой `git ls-files` (опоры отчётов «не разрешились») — артефакты способа воспроизведения,
           не свойства коммита; в рабочем дереве на HEAD ac-096 зелёный
```

Вывод: заявка README «22 красных / 2 зелёных» по контентной части воспроизведена точно (22 контентных красных, warden зелёный от рождения); краснота композита в песочнице — env способа воспроизведения, к вердикту приёмки на HEAD отношения не имеет. Цепочка red → green подтверждена собственной рукой.

---

## Контрактные спот-чеки сверх стабов (собственные grep/diff по всему дереву)

### Четыре override'а RES-008 (BR-015)

| # | Override | Наблюдение (собственный grep, всё дерево writer) | Вердикт |
|---|---|---|---|
| 1 | Без `<gallery>` и `Gantt` | `grep -rn '<gallery'` — 0 вхождений; `grep -rn 'display="Gantt"'` — 0; слово «Gantt» единожды — в негативной прозе без литеральной формы (blocks.md:127, «Значение Gantt … в движке отсутствует — не указывать») | соответствует |
| 2 | Ссылки: правило + оговорка | правило «без `.md`» сохранено (SKILL.md:232, «Канон для новых ссылок — форма без .md»); оговорка «обе формы резолвятся движком и офлайн-валидатором» (SKILL.md:231) | соответствует |
| 3 | `<view>`: defs — сокрытие | таблица blocks.md:123 — «Фильтр сокрытия: перечисленные значения исключают статьи…; `none` — только статьи, у которых свойство есть; `yes` — только без него»; `hierarchy=child-to-current` — запись внутри `defs` (пример :112); `orderby`/`select`/`Kanban` на местах; старый перевёрнутый пример (`Тип контента=ADR…`) — 0 вхождений; старая формулировка «фильтр отбор» — 0; пометка NFR-071 «прежняя формулировка… была обратной» — blocks.md:144 | соответствует |
| 4 | Изображения: scale/размеры | «`width`/`height` — реальный размер файла в пикселях» (blocks.md:372); `scale` — только атрибут XML-формы `<image scale="…"/>`; markdown-аннотация ограничена (blocks.md:360: «применяется к `width` и `height` (engine: imgSizePlugin.ts:24-25); для `scale` используйте XML-форму»); формы `{scale` в дереве — 0 вхождений; `<gallery` — 0 | соответствует |

### Негатив `cover` (Q4)

`grep -rn 'cover='` по дереву writer — 0 вхождений (форма атрибута не воспроизводится); слово — единожды, в негативной пометке blocks.md:324-325 («атрибут обложки cover … в движке на пине не найден — не использовать в новом контенте»). Соответствует дизайну и warden-ассерту ac-082.

### Диф `gramax-tags.json` против контракта NFR-072 (git diff `a59db10` → HEAD, прочитан целиком)

| Проверка | Ожидание (дизайн) | Факт | Вердикт |
|---|---|---|---|
| `selfClosingTags` | +9: fragment, property, inline-property, img-h, img-v, cmd, kbd, alfa, beta | ровно эти 9 | соответствует |
| `pairedTags` | +4: fragment-link, cut, question, questionAnswer | ровно эти 4 | соответствует |
| `schemaVersion` | остаётся 2 | 2 | соответствует |
| `snippet` | остаётся (NFR-071, legacy-алиас) | присутствует | соответствует |
| `diagramTags` | не трогается (ADR-0024) | `drawio, mermaid, plant-uml, bpmn` — без изменений | соответствует |
| прочие ключи | нет | только существующий `legacy` | соответствует |

### Миграция `docs/.doc-root.yaml`

`git diff a59db10 → HEAD`: строка `filterProperties: [Тип контента, Статус, Плагин]` удалена, внесена `filterProperty: Тип контента` с комментарием-обоснованием (движок читает одиночную форму, `CatalogProps.ts:17`; RES-008 Q1б). Ключ на месте (:32), старой формы в файле нет. Соответствует вердикту Q1б.

### Качество сверх маркеров (выборочно)

- Палитра `style`: 20 значений enum движка + отдельная legacy-строка 11 значений writer 4.6.0 с явным перечнем 6 вне-enum значений и пометкой «не использовать в новом контенте» (doc-root-schema.md:110-114) — механизм FR-175/NFR-071 соблюдён.
- `filterProperties` сохранена одной legacy-строкой с пометкой «движком не читается; миграция — заменить» (doc-root-schema.md:34-35) — по Q1б, не молчаливая замена.
- enum `syntax`: три значения движка + пометка деградации «`syntax: Markdown` фактически работает как `Legacy`» (doc-root-schema.md:51-52) — NFR-071 соблюдена.
- quizzes.md: все 12 типов присутствуют; каждая строка атрибутов несёт источник (`engine` с `путь:строка` / docs / «поверхность GES»); `showIf` явно помечен «в OSS-дереве не найден — поверхность GES» (:108-109).
- Guardrails SKILL.md: hard rule `template:` с политикой Q3 (правка файла шаблона — только по явному запросу), `.gramax/inbox/`, `.gramax/mr/`, LFS-указатели; staging-чеклист уточнён до «фрагменты/сниппеты» (SKILL.md:392, 407-417).

---

## Регрессионный анализ

- **Восемь соседних suite — 101/101, все rc=0** (таблица в Summary): writer-consumer-rules (другое требование, подключён к живому `--full`), link-form-resolver, link-form-migration, mermaid-adoption, plantuml-bpmn, export-skill, catalog-validator (весь прежний пласт 36), plugin-contract. Ни один сосед не сузился.
- **NFR-071 (аддитивность) подтверждена содержанием:** `snippet` в контракте и в справочнике как legacy; скобочные формы `[cmd:` сохранены (AC-080); legacy-строки палитры/`filterProperties`/`syntax: Markdown` не удалены, а помечены; оговорка о `.md`-форме информационная, правило FR-080 не тронуто.
- **Регистрация suite:** `scripts/check-gramax.sh` — writer-sync-470 вставлен шагом 15 (`--full` only) коммитом Dev; `--fast` suite не исполняет, рекурсии ac-096 нет — вечного цикла не возникло.
- **plugin-contract 7/7** — инварианты поставки плагина не тронуты.

---

## Failed tests (детали)

**Финальное состояние на HEAD `03011ee`: ни один тест не падает.** Классификация отказов сессии:

| Категория | Кол-во | Что вошло |
|---|---|---|
| regression | 0 | — |
| new | 0 | — |
| flaky | 0 | — |
| env | 0 (до записи отчёта) | ожидаемая собственная C1 после записи — см. «Постпроверка»; краснота ac-096 в песочнице архива — env способа воспроизведения, вне приёмки |

Красных линий «не принимать merge без подтверждённого flaky/env» не задето: принимать нечего — отказов нет.

---

## Не покрыто автоматикой — ревью-пункты с владельцем (зафиксированы, не засчитаны как PASS)

| # | Пункт | Почему не покрыт | Состояние на прогоне | Владелец проверки |
|---|---|---|---|---|
| 1 | markdown-форма `{scale=…}` | grep `scale=` AC-081 сматчится и на ошибочно задокументированную рабочую `{scale=…}`; движок применяет из аннотации только `width`/`height` (imgSizePlugin.ts:24-25) — осознанная слепая зона дизайна | чисто: `{scale` в дереве writer — 0 вхождений; scale дан только XML-формой с оговоркой (blocks.md:360) | ревьюер (процессная проверка при следующих правках раздела) |
| 2 | AC-075 — docs-поверхность GES | тест проверяет наличие строк `showIf`/`mode`/`shuffleQuestions`, не engine-семантику (её в OSS-дереве нет — открытый вопрос 3 дизайна) | пометки источника на месте; `showIf` явно «поверхность GES» (quizzes.md:108-109) | SA/PM — верификация при первом окне с исходниками GES |
| 3 | AC-082 — амбивалентность `cover` | позитивный grep не различает позитивное и негативное употребление слова | употребление негативное, формы `cover=` нет (см. спот-чек) | ревьюер (процессная проверка) |
| 4 | AC-096 — внешняя обусловленность | композит краснеет от любого незарегистрированного файла любых параллельных потоков | на момент вердикта `Errors: 0`; после записи отчёта — ожидаема собственная C1 до PM-wiring | PM (регистрация строки отчёта в `_index.md`) |

---

## Контекст прогона (находки вне AC — не блокируют, требуют действий вне QA)

1. **C6 валидатора контента стал no-op для `docs/` после миграции — наблюдаемый эффект, follow-up апстриму, не дефект потока.** `scripts/validate-content.py:123-125` (`check_filter_coverage`) читает `doc_root.get("filterProperties")`; после миграции ключа в `docs/.doc-root.yaml` нет → пустой набор → ранняя `return []` для всего `docs/`. Наблюдение: гейт `Warnings: 6` — все TPL-69 на досинтезных файлах, находок C6 ноль. Кандидат апстрим-фикса: научить C6 читать engine-форму `filterProperty` (одиночный id, матч по правилу `id ?? name`). Зона валидатора — вне среза writer.
2. **Запись `Contract:` в `plugins/gramax/CHANGELOG.md` (4.7.0) в дереве отсутствует** — `grep '4\.7\.0\|Contract'` находит только исторические записи. По дизайну это шаг 7 (Dev/Tech-writer), по NFR-072 запись обязательна; прецедент предыдущей волны — перенос в PM-пакет. Действие для PM/Tech-writer до release.
3. **Провenance миграции `docs/.doc-root.yaml`:** текст дизайна назначал её PM («правка не входит в срез writer»), фактически исполнена Dev внутри коммита потока `03011ee`; бриф координатора прямо называет миграцию частью реализации под приёмку — расхождение снято брифом, зафиксировано для истории.
4. **Bump версии 4.6.0 → 4.7.0** (`plugin.json`/`marketplace.json`) на момент прогона не сделан — плановый шаг Tech-writer/PM при выпуске (прецедент предыдущей волны), не дефект.

---

## Рекомендация

- [x] **accept** — передача в BA-acceptance / `pm-review`
- [ ] fix-first (block + назад в Dev)
- [ ] re-run (flaky)

**Обоснование:** приёмочный suite зелёный при независимом прогоне (24/24), каждый AC-073…AC-096 прослеживается до PASS и скрипта suite, и дословной формулы требования; красный старт TDD-цепочки воспроизведён архивом red-phase-коммита (22 контентных красных + warden — точно по README); четыре override'а RES-008 (без gallery/Gantt, оговорка ссылок, defs=сокрытие, scale/реальные размеры) и негатив `cover` подтверждены собственными grep по всему дереву; диф `gramax-tags.json` — в точности контракт NFR-072 (9+4, schemaVersion 2, snippet и diagramTags не тронуты); миграция `filterProperty` на месте. Регрессионный пласт — 101/101 по восьми соседним suite. Отказов нет; ревью-пункты слепых зон зафиксированы с владельцами и не маскируются под PASS. Действия вне Dev до release: (1) PM — регистрация строки этого отчёта в `_index.md` (снимет собственную C1); (2) PM/Tech-writer — запись `Contract:` 4.7.0 в CHANGELOG и bump версии; (3) апстрим-кандидат — адаптация C6 валидатора к `filterProperty`.

**Передача:** BA-acceptance gate → Tech-writer. Код продукта, тесты и контент навыка этой QA-сессией не менялись (красная линия роли); единственный артефакт сессии в дереве — этот отчёт.

---

## Постпроверка

Фиксируется после записи отчёта (измерено фактически):

```text
$ bash scripts/check.sh --fast; echo "GATE_RC=$?"
GATE_RC=1     # Errors: 1 | Warnings: 7 — единственный error — C1 ЭТОГО отчёта:
# «…2026-11-18-writer-sync-470-qa-report.md: не зарегистрирована ссылкой в
# docs/60-implementation/test-reports/_index.md …» + C10-orphan [warning] на тот же файл.
# Остальные 6 warnings — прежние TPL-69 досинтезных файлов. Бриф прямо ожидает own-file C1
# («no _index.md — PM wires»); регистрацию строки делает PM. «Опоры» отчёта гейтом подтверждены.

$ bash tests/gramax/writer-sync-470/run.sh   # после записи: 23/24 — red только ac-096
$ bash tests/gramax/export-skill/run.sh      # после записи: 9/10 — red только ac-050-composite-gate
```

**Разведение вердиктов (честно, без смешения):** AC-096 измерен по дереву ДО записи отчёта — `rc=0`, `Errors: 0 | Warnings: 6` (строка «Композит» таблицы Summary). Краснота ac-096 и ac-050 ПОСЛЕ записи детерминирована единственной собственной C1 этого отчёта в общем гейте (обе зависимости — `check.sh --fast` внутри стаба; класс **env** по прецеденту инструментария: незарегистрированный файл любого потока переворачивает гейт-зависимые шаги) и снимается регистрацией строки отчёта в `_index.md` без единой правки кода/тестов. Содержательные AC-073…AC-095 зелёны в обоих состояниях.
