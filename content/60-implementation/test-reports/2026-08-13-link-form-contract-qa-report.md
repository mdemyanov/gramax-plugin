---
title: "QA Report — контракт формы ссылки на артефакт (link-form-contract, 4.3.0)"
order: 8
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# QA Report — контракт формы ссылки на артефакт (`link-form-contract`, 4.3.0)

**Дата прогона:** 2026-08-12/13
**Ветка/дерево:** `worktree-link-form-impl`, HEAD `fc2ff21`, дерево чистое (`git status --porcelain` — пусто, проверено до и после прогона)
**Диапазон волны:** `2996de4`…`fc2ff21` — резолвер (`51252ed`), миграция (`2996de4`…`d743750`), подключение обоих suite к `check.sh --full` (`fc2ff21`)
**Tester:** QA-runner (независимый повторный прогон — не полагался на заявленный PM результат)
**Требование:** [Контракт формы ссылки на артефакт в Gramax-каталоге](../../30-requirements/2026-08-13-link-form-contract.md) (AC-001…019)
**ADR:** [0016-link-form-contract.md](../../00-project/adr/0016-link-form-contract.md)
**Архитектура:** [Контракт формы ссылки на артефакт — резолвер, миграция, интеграция с nauta](../../40-architecture/2026-08-13-link-form-contract-design.md)
**AT-design (qa-author, резолвер):** [2026-08-13-link-form-contract-resolver-at-design.md](../acceptance/2026-08-13-link-form-contract-resolver-at-design.md)
**AT-design (qa-author, миграция):** [2026-08-13-link-form-contract-migration-at-design.md](../acceptance/2026-08-13-link-form-contract-migration-at-design.md)
**Dev notes:** [2026-08-13-link-form-contract-migration-dev-notes.md](../2026-08-13-link-form-contract-migration-dev-notes.md)

---

## Summary

| Suite/проверка | Команда | Passed | Failed | Skipped | Exit |
|---|---|---|---|---|---|
| `link-form-resolver` (приёмка, резолвер) | `bash tests/gramax/link-form-resolver/run.sh` | 8 | 0 | 0 | `0` |
| `link-form-migration` (приёмка, миграция) | `bash tests/gramax/link-form-migration/run.sh` | 7 | 0 | 0 | `0` |
| `pytest` (regression, валидатор) | `uv run pytest plugins/gramax/scripts/tests/ -q` | 9 | 0 | 0 | `0` |
| `nauta-integration` (regression) | (внутри `--full`) | 8 | 0 | 0 | `0` |
| `plugin-contract` (regression) | (внутри `--full`) | 7 | 0 | 0 | `0` |
| `doc-paths` (regression) | (внутри `--full`) | 2 | 0 | 0 | `0` |
| `catalog-validator` (regression) | (внутри `--full`) | 13 | 0 | 0 | `0` |
| `mermaid-adoption` (regression) | (внутри `--full`) | 10 | 0 | 0 | `0` |
| `writer-consumer-rules` (regression) | (внутри `--full`) | 11 | 0 | 0 | `0` |
| **Итого (AC/гейт-скрипты)** | | **75** | **0** | **0** | — |
| Композит `check.sh --fast` (AC-019) | `bash scripts/check.sh --fast` | — | — | — | `0` |
| Композит `check.sh --full` (13 шагов, 66 AC внутри) | `bash scripts/check.sh --full` | — | — | — | `0` |

- **passed:** 75 (7 миграция + 8 резолвер + 9 pytest + 51 из шести уже существовавших regression-suite, все они же входят в `--full`)
- **failed:** 0
- **skipped:** 0
- **total:** 75
- **duration:** `check.sh --fast` ≈ 0.99 c; `check.sh --full` ≈ 18.18 c; `pytest` ≈ 0.71 c; `link-form-resolver` и `link-form-migration` suite входят в общее время `--full`
- **Итог одной строкой:** полный пак (не subset) прогнан независимо от заявления PM и дал 100% зелёный результат по всем формальным гейтам и AC-скриптам (75/75, оба новых suite 15/15, регрессия по 6 существующим suite 51/51 без изменения счёта, pytest 9/9); AC-017/AC-018 подтверждены буквальным выполнением команд из at-design, не пересказом. Найдена ОДНА low-severity, неблокирующая находка (раздел «Находки» ниже) — самопроверка идемпотентности миграции на живом `content/` даёт `To-migrate: 2`, не `0`, из-за двух NAV-код-спанов в самом `dev-notes`-документе, написанном ПОСЛЕ последнего коммита миграции. Рекомендация — **merge** (готово к передаче Tech-writer/`pm-review`), находка — в бэклог Dev, не блокер.

---

## Прогон suite → команда → код возврата (честный `$?`, не grep)

| # | Проверка | Команда | Код возврата (1-й прогон) | Код возврата (2-й прогон, независимая проверка стабильности) |
|---|---|---|---|---|
| 1 | Fast gate (AC-019) | `bash scripts/check.sh --fast` | `exit=0` | `exit=0` |
| 2 | Full gate (13 шагов, агрегатор) | `bash scripts/check.sh --full` | `exit=0` | `exit=0` |
| 3 | pytest-регрессия валидатора | `uv run pytest plugins/gramax/scripts/tests/ -q` | `exit=0` (9 passed) | — (не потребовалось: не было ни одного failed, для 3-кратного прогона нужен только failed-кейс) |
| 4 | AC-017, шаг 1 (протухшая цель отсутствует) | `grep -q '…mermaid-file-based-adoption.md' content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md; echo $?` | `stale_ref_exit=1` | — |
| 5 | AC-017, шаг 2 (валидатор чист) | `uv run plugins/gramax/scripts/validate_structure.py content; echo $?` | `exit=0` | — |
| 6 | AC-018 (дрейф `путь:строка`) | команда из at-design (см. ниже) | `cited=10 actual=10 record_marker_count=0` | — |
| 7 | Orphan-регресс | `uv run scripts/validate-content.py` (входит и в `--fast`) | `Errors: 0 \| Warnings: 0`, `exit=0` | — |
| 8 | Идемпотентность миграции (самопроверка) | `uv run plugins/gramax/scripts/migrate_nav_codespans.py content` | `To-migrate: 2` (см. «Находки») | `To-migrate: 2`, идентично — детерминировано, не flaky |
| 9 | `git status --porcelain` до/после всего прогона | — | пусто | пусто — QA-runner не изменил рабочее дерево |

Оба композита (`--fast`, `--full`) и находка №8 прогнаны дважды независимо — идентичный результат оба раза, не flaky.

Полный непрефильтрованный вывод `--full` (13 `==>`-шагов) прочитан целиком: `whitespace` → OK, `json` → OK,
`content` → `Errors: 0 | Warnings: 0`, `shellcheck` → `OK: shellcheck clean`, `submodule status` → `OK`,
`orphan-references` → `PASS`, шесть регрессионных AC-suite (`nauta-integration` 8/8, `plugin-contract` 7/7,
`doc-paths` 2/2, `catalog-validator` 13/13, `mermaid-adoption` 10/10, `writer-consumer-rules` 11/11) — все
`All N AC tests passed.`, оба новых suite (`link-form-resolver` 8/8, `link-form-migration` 7/7) — тоже
`All N AC tests passed.`, финальная строка `==> RESULT: PASS`.

---

## AC coverage (сверка с at-design qa-author — шаг 1 процесса)

Оба at-design (резолвер + миграция) заявляют 19 из 19 AC требования покрытыми: 15 исполняемым bash-скриптом
(AC-001…012), 2 задокументированной командой на реальном `content/` (AC-017, AC-018), 4 намеренно процессных
(AC-013…016, чек-лист `pm-review`, не территория QA-runner по прямому указанию задачи), 1 композитный
(AC-019). Пропусков stubs от qa-author нет — блок-фактора «тестов нет, а stubs были» не найдено.

| AC | Скрипт/команда | Результат | Класс |
|---|---|---|---|
| AC-001 | `ac-001-nav-classification-deterministic.sh` | PASS | закрыт Dev, миграция |
| AC-002 | `ac-002-self-priority.sh` | PASS | закрыт Dev, миграция |
| AC-003 | `ac-003-disputed-case-nav.sh` | PASS | закрыт Dev, миграция (прецедент #83) |
| AC-004 | `ac-004-scope-boundary-subject.sh` | PASS | закрыт Dev, миграция (самый сложный AC трека, см. at-design) |
| AC-005 | `ac-005-migration-form.sh` | PASS | закрыт Dev, миграция |
| AC-006 | `ac-006-antipattern-documented.sh` | PASS | закрыт Dev, `SKILL.md` содержательный пример |
| AC-007 | `ac-007-cross-catalog-not-migrated.sh` | PASS | regression guard |
| AC-008 | `ac-008-no-extension-resolves.sh` | PASS | закрыт Dev, резолвер (FR-082 шаг 2) |
| AC-009 | `ac-009-section-index-resolves.sh` + `ac-009b` (edge) | PASS | закрыт Dev, резолвер |
| AC-010 | `ac-010-doc-root-prefix-antipattern-stays-broken.sh` + `ac-010b` (edge) | PASS | regression guard (антипаттерн FR-081 не резолвится) |
| AC-011 | `ac-011-genuinely-broken-link-detected.sh` + `ac-011b` (edge) | PASS | regression guard (NFR-001, инвариант) |
| AC-012 | `ac-012-outside-catalog-codespan-ignored.sh` | PASS | regression guard (граница FR-084) |
| AC-013 | процессная (чек-лист `pm-review`) | вне периметра QA-runner | явно указано задачей, не проверялось |
| AC-014 | процессная (чек-лист `pm-review`) | вне периметра QA-runner | явно указано задачей, не проверялось |
| AC-015 | процессная (чек-лист `pm-review`) | вне периметра QA-runner | явно указано задачей, не проверялось |
| AC-016 | процессная (чек-лист `pm-review`) | вне периметра QA-runner | явно указано задачей, не проверялось |
| AC-017 | grep + `validate_structure.py` (команды at-design, буквально) | PASS: `stale_ref_exit=1`, `exit=0` | закрыт Dev, content-правка FR-092(b) |
| AC-018 | grep-команда at-design (буквально) | PASS: `cited=10 actual=10` | закрыт Dev, content-правка FR-092(d) |
| AC-019 | `bash scripts/check.sh --fast && echo PASS` | PASS: `exit=0` (2 независимых прогона) | композит, регрессия по коду возврата |

Независимая проверка AC-017/AC-018 (буквальные команды из `2026-08-13-link-form-contract-migration-at-design.md`,
разделы «AC-017 — протухший путь», «AC-018 — дрейф путь:строка»), не только по факту зелёного suite:

```
$ grep -q 'content/60-implementation/acceptance/2026-08-11-mermaid-file-based-adoption.md' \
  content/60-implementation/acceptance/2026-08-11-mermaid-adoption-at-design.md
$ echo "stale_ref_exit=$?"
stale_ref_exit=1

$ uv run plugins/gramax/scripts/validate_structure.py content
$ echo "exit=$?"
exit=0

$ CITED=$(grep -oE 'adr/_index\.md:[0-9]+' content/30-requirements/2026-08-11-writer-consumer-rules.md \
  | head -1 | grep -oE '[0-9]+$')
$ RECORD_MARK=$(grep -c 'RECORD' content/30-requirements/2026-08-11-writer-consumer-rules.md)
$ ACTUAL=$(grep -n 'Статусы:.*Proposed.*Accepted.*Superseded by ADR-MMMM' content/00-project/adr/_index.md \
  | head -1 | cut -d: -f1)
$ echo "cited=$CITED actual=$ACTUAL record_marker_count=$RECORD_MARK"
cited=10 actual=10 record_marker_count=0
```

Оба ожидания at-design выполнены буквально: у AC-017 протухшая цель `2026-08-11-mermaid-file-based-adoption.md`
(старое имя-гомоним) отсутствует в тексте (`stale_ref_exit=1`), и построчная проверка подтвердила, что вместо
неё вписана рабочая ссылка `[Принятие file-based mermaid потребителями…](2026-08-11-mermaid-file-based-adoption.md)`
на строке 17 (заголовок «Требование:»); у AC-018 `cited == actual == 10` — дрейф `11→10` устранён, POINTER
верен на HEAD прогона (`record_marker_count=0` — не нужен, т.к. номера совпали).

---

## Регрессионный анализ

### Существующие 6 regression-suite — счёт не изменился

`nauta-integration` 8, `plugin-contract` 7, `doc-paths` 2, `catalog-validator` 13, `mermaid-adoption` 10,
`writer-consumer-rules` 11 — все шесть дают **тот же счёт AC**, что и в предыдущем отчёте
(`2026-08-13-cross-catalog-retraction-qa-report.md`, где эти же 51 AC уже были зафиксированы зелёными после
ретировки `writer-consumer-rules` 12→11). Ни один тест не покраснел, ни один AC не исчез и не появился в этих
шести suite. Прирост `--full` (66 AC против 51 в предыдущем отчёте) объясняется ИСКЛЮЧИТЕЛЬНО двумя новыми
suite этой волны (`link-form-resolver` +8, `link-form-migration` +7 = +15), не изменением существующих.

### pytest-регрессия валидатора — зелёная

`uv run pytest plugins/gramax/scripts/tests/ -q` → `9 passed in 0.71s`, `exit=0`. Этот suite не подключён к
`check.sh`, прогоняется отдельно по README/CLAUDE.md — независимое подтверждение, что резолвер (`51252ed`)
не сломал существующее unit-покрытие `validate_structure.py`.

### Orphan-регресс (п.5 задачи) — 0, без немотивированного роста

`content/: OK (69 файлов проверены)`, `Errors: 0 | Warnings: 0` — как в составе `check.sh --fast`/`--full`,
так и при прямом вызове `uv run scripts/validate-content.py`. Задача просила базу для сравнения — состояние
ДО волны на коммите `8b31865` (0 warnings). Текущее состояние: тоже 0 warnings — регресса по числу сирот нет,
несмотря на то, что корпус вырос примерно на 15+ файлов этой волной (ADR-0016…0018, at-design'ы, RES-005,
резолвер/миграция dev-notes). Каждая новая статья корректно связана (входящие ссылки из `_index.md` разделов
+ новые markdown-ссылки от миграции), C10 не сработал ни разу.

### NFR-001 (обратная совместимость резолвера) — подтверждена

Покрывается шагом 2 (`check_broken_links` внутри `--fast`/`--full`, `Errors: 0`). Корпус вырос с 68
markdown-ссылок (снимок RES-005 до волны) до значительно большего числа после миграции 145 NAV-код-спанов —
все резолвятся, 0 битых, включая старые ссылки с явным `.md` (форма 3/4 RES-004) и новые без расширения
(форма FR-080) и с временным `.md`-суффиксом (протокол ADR-0016 Решение 2, форма миграции FR-092/at-design).
Инвариант NFR-001 («резолвер не может ослабить детекцию генуинно битой ссылки») независимо подтверждён
`AC-011`/`AC-011b` (regression guard, safeguards) — оба зелёные.

**Вывод:** регрессий не найдено ни в одном из семи проверенных пластов (6 существующих AC-suite, pytest,
orphan-счёт, резолвер обратной совместимости).

---

## Находки

### Находка №1 — идемпотентность миграции на живом `content/`: `To-migrate: 2`, не `0` (low, non-blocking)

**Severity:** Low (информационная, не блокирует ни один AC/гейт).
**Репро-команда:**

```
$ uv run plugins/gramax/scripts/migrate_nav_codespans.py content
60-implementation/2026-08-13-link-form-contract-migration-dev-notes.md:35 NAV -> ../30-requirements/2026-08-11-mermaid-file-based-adoption.md
60-implementation/2026-08-13-link-form-contract-migration-dev-notes.md:110 NAV -> ../_index.md
To-migrate: 2
SELF: 16
SUBJECT: 291
$ echo $?
1
```

Воспроизведено дважды подряд (два независимых прогона), результат идентичен — **детерминировано, не flaky**.

Задача (п.6) ожидала `To-migrate: 0` как подтверждение фикса идемпотентности (`ddeed43`, «окно маркеров после
мутации»). Фактически на HEAD `fc2ff21` результат — `To-migrate: 2`. Разбор причины (не правка — красная линия
роли):

- Оба кандидата — в файле [Dev notes: классификация и миграция NAV-код-спанов (ADR-0016)](../2026-08-13-link-form-contract-migration-dev-notes.md),
  который создан коммитом `d743750` — **после** последнего коммита самой миграции (`e853c2b`, `60-implementation`)
  и после фикса идемпотентности (`ddeed43`). Этот dev-notes документ описывает уже завершённую миграцию (в том
  числе цитирует протухший путь AC-017 и дефолт текста ссылки) и сам никогда не прогонялся через
  `migrate_nav_codespans.py --fix`.
- Строка 35: `…исправлен на \`content/30-requirements/2026-08-11-mermaid-file-based-adoption.md\`.` внутри
  нумерованного пункта списка (`3. …`) — классификатор помечает NAV предположительно через эвристику
  «структурный маркер пункта списка» (dev-notes сам же описывает эту эвристику в разделе «Неочевидное —
  эвристика directionality», «Структурный маркер пункта списка... маркер у метки применяется ко ВСЕМ элементам
  перечисления»). Фраза ретроспективна («исправлен на», факт истории), не императивна («см.») — граничный
  случай применения directionality-теста FR-077, не однозначная ошибка классификатора.
- Строка 110: `…кроме двух случаев \`content/_index.md\` → «Gramax Marketplace»…` внутри маркированного пункта
  (`- Текст ссылки…`) — тот же класс граничного случая.
- Оба кандидата ведут к реально существующим, принадлежащим каталогу целям (`../30-requirements/…md`,
  `../_index.md`) — под-миграция здесь **безопасного направления**: не создаёт битой ссылки, просто оставляет
  код-спан там, где по логике `migrate_nav_codespans.py` (применённой к тексту dev-notes так же, как к любому
  другому файлу) появился бы NAV-кандидат.

**Почему не блокирует:** report-mode `migrate_nav_codespans.py` НЕ подключён к `check.sh` (явное решение
qa-author/Dev, зафиксировано в at-design миграции, раздел «Запуск» — «НЕ подключён к `scripts/check.sh` —
подключение... решает PM/Dev отдельно»); ни один AC требования (AC-001…007, AC-017, AC-018) не формулирует
«живой `content/` в целом обязан давать `To-migrate: 0` на любой момент времени» — этот инвариант нигде не
зафиксирован ADR/требованием как постоянно проверяемый гейт, только как ожидание конкретно этой QA-runner
задачи (п.6 брифа PM). `check.sh --fast`/`--full` зелёные независимо от этой находки.

**Рекомендация Dev/PM:** на выбор — (а) прогнать `migrate_nav_codespans.py --fix --yes` точечно на dev-notes
и вручную свериться, что обе получившиеся ссылки корректны (текст/путь), либо (б) явно принять эти два
код-спана как задокументированный остаток (по прецеденту уже принятых ~30 недомигрированных строк, dev-notes,
раздел «Не покрыто / известные ограничения») и зафиксировать это решение. Не блокирует передачу дальше по
конвейеру — заносится как input для Dev как «дальше по списку», не как дефект, требующий отката волны.

### Других находок нет

Ни резолвер, ни миграция, ни регрессионные suite, ни pytest не показали ни одного дефекта сверх находки №1.
Все AC требования (кроме намеренно процессных AC-013…016, вне периметра QA-runner) закрыты и подтверждены
буквальным выполнением команд, не пересказом отчёта Dev.

---

## Performance snapshot (контекст, не NFR-гейт)

NFR-002 требования явно не фиксирует числовой порог («не измерено на кратно большем каталоге» — открытый
вопрос №5). Snapshot ниже — для контекста относительно предыдущего QA-отчёта волны, не проверка обязательного
AC:

| Метрика | Baseline (`2026-08-13-cross-catalog-retraction-qa-report.md`, 7 suite/51 AC в `--full`) | Текущий (9 suite/66 AC в `--full`) | Дельта |
|---|---|---|---|
| `check.sh --full`, real time | ≈ 14.5 c | ≈ 18.18 c | +3.7 c |
| `check.sh --fast`, real time | ≈ 0.84 c | ≈ 0.99 c | +0.15 c |
| Живых AC в `--full` | 51 | 66 (+15: `link-form-resolver` +8, `link-form-migration` +7) | +15 AC |
| Файлов в `content/` (`validate-content.py`) | не зафиксировано в baseline-отчёте явно | 69 | — |

Рост времени `--full` (+3.7 c, ≈+25%) пропорционален росту числа живых AC (+15, ≈+29%) — в пределах ожидаемого
масштабирования, не аномалия. `pytest`-suite (0.71 c) и оба новых bash-suite (входят в общее время `--full`)
не показывают признаков деградации по сравнению с сопоставимыми по размеру существующими suite
(`catalog-validator`, 13 AC, тот же порядок величины).

---

## Failed tests (детали)

Ни один тест/AC-скрипт не упал ни в одном из семи прогнанных пластов (2 новых suite, pytest, 6 существующих
regression suite, 2 композита). Таблица `Failed tests` — пуста намеренно, не пропущена молча. Единственное
отклонение от буквального ожидания задачи (п.6, идемпотентность) зафиксировано выше как «Находка №1» — это не
падение теста (никакой suite/скрипт не проверяет и не требует `To-migrate: 0` как условие PASS/FAIL), а
самостоятельная диагностическая проверка QA-runner.

---

## Рекомендация

- [x] merge (готово к передаче Tech-writer / `pm-review`)
- [ ] block + назад в Dev
- [ ] re-run (flaky)

**Обоснование:** полный пак прогнан независимо от заявления PM (не subset, не «только новые тесты») —
75/75 AC-скриптов зелёные (15 новых: 8 резолвер + 7 миграция; 51 регрессия по 6 существующим suite без
изменения счёта; 9 pytest), оба композита (`--fast`/`--full`) зелёные при двух независимых прогонах каждый,
AC-017/AC-018 подтверждены буквальным выполнением команд at-design (не пересказом), orphan-счёт не вырос
(0, как и до волны), NFR-001 (обратная совместимость резолвера) подтверждён нулём битых ссылок на выросшем
корпусе. Единственная находка (self-check идемпотентности миграции даёт `To-migrate: 2`, не `0`) —
low-severity, не блокирует ни один AC/гейт (report-mode не подключён к `check.sh`, ни один AC требования не
формулирует это как постоянный инвариант), воспроизведена дважды идентично (не flaky), причина понятна и
безопасного направления (под-миграция, не ложная ссылка). Блокеров для передачи дальше по конвейеру не найдено.

**Передача:** Tech-writer/`pm-review` — следующая фаза (AC-013…016, процессные пункты по цитированию и
forward+back linking, плюс, при желании, точечная зачистка находки №1 в dev-notes). Код/тесты этой QA-сессией
не менялись (красная линия роли) — единственные новые файлы: этот отчёт и обновлённая строка в
`test-reports/_index.md`.

---

## Постпроверка

После записи этого отчёта и добавления строки в `test-reports/_index.md`:

```
$ bash scripts/check.sh --fast; echo "exit=$?"
exit=0
```

`git status --porcelain` до и после записи артефактов QA-runner — единственные изменения: этот файл и строка
в `_index.md` (правки кода продукта/тестов/`content/`-контента не вносились, по красной линии роли QA-runner).
