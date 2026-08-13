---
title: "QA Report — рекурсивное обнаружение .doc-root.yaml и типизация полей (validate_structure.py, 4.5.0)"
order: 10
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# QA Report — рекурсивное обнаружение `.doc-root.yaml` и типизация полей (FR-120…123, ADR-0020)

**Дата прогона:** 2026-08-13
**Ветка/дерево:** `main`, HEAD `4958238` + незакоммиченная фича (требование, ADR-0020, реализация, suite, фикстуры — рабочее дерево; `git status --short`)
**Tester:** QA-runner (независимый прогон, не полагался на заявленный Dev-результат)
**Требование:** [Контракт .doc-root.yaml: рекурсивное обнаружение и типизация title](../../30-requirements/2026-08-13-doc-root-discovery-contract.md) (FR-120…FR-123, AC-036…AC-040)
**ADR:** [0020-doc-root-recursive-discovery.md](../../00-project/adr/0020-doc-root-recursive-discovery.md) (Решения 1–3, 5, 6)
**AT-design (qa-author):** отдельного файла нет — AC-036…AC-040 живут в теле требования; suite `tests/gramax/catalog-validator/` (ac-021…ac-024.sh) покрывает AC-036…AC-039 1:1, AC-040 — догфудинг `ac-001-dogfood-clean-exit.sh`

---

## Summary

| Suite/проверка | Команда | Passed | Failed | Skipped | Exit |
|---|---|---|---|---|---|
| Fast gate (pre-commit) | `bash scripts/check.sh --fast` | — | — | — | `0` |
| `catalog-validator` (приёмка, ac-001…ac-024) | `bash tests/gramax/catalog-validator/run.sh` | 24 | 0 | 0 | `0` |
| pytest `test_validate_structure.py` (unit) | `uv run pytest plugins/gramax/scripts/tests/test_validate_structure.py` | 15 (+4 subtest) | 0 | 0 | `0` |
| Full gate (регрессия) | `bash scripts/check.sh --full` | 15 шагов из 16 | 1 (shellcheck SC2034, pre-existing) | 0 | `1` |
| `orphan-references` (regression) | (внутри `--full`) | PASS | 0 | — | `0` |
| `nauta-integration` (regression) | (внутри `--full`) | 8 | 0 | 0 | `0` |
| `plugin-contract` (regression) | (внутри `--full`) | 7 | 0 | 0 | `0` |
| `doc-paths` (regression) | (внутри `--full`) | 2 | 0 | 0 | `0` |
| `catalog-validator` (regression, внутри `--full`) | (внутри `--full`) | 24 | 0 | 0 | `0` |
| `mermaid-adoption` (regression) | (внутри `--full`) | 10 | 0 | 0 | `0` |
| `writer-consumer-rules` (regression) | (внутри `--full`) | 11 | 0 | 0 | `0` |
| `link-form-resolver` (regression) | (внутри `--full`) | 8 | 0 | 0 | `0` |
| `link-form-migration` (regression) | (внутри `--full`) | 7 | 0 | 0 | `0` |
| `render-linter` (regression) | (внутри `--full`) | 21 | 0 | 0 | `0` |
| **Итого (AC-скрипты)** | | **98** | **0** | **0** | — |

- **passed:** 98 AC-скриптов (24 catalog-validator + 74 регрессия по остальным 8 suite) + 15 pytest-тестов (4 новых класса: `NestedDocRootDiscoveryTests`, `NestedDocRootDemarcationTests`, `DocRootTitleTypeTests`, `DocRootParseErrorTests`) + 4 не-AC шага `--full` (whitespace, json, content, render) + submodule
- **failed:** 1 — `shellcheck SC2034` в `tests/gramax/render-linter/ac-012-dedup-w034.sh:20` (`RC=$?` не используется). Классификация: **pre-existing** (коммит `562325e`, render-killer-linter 4.4.0; в diff этой задачи файл не входит). НЕ блокер фичи FR-120…123.
- **skipped:** 0
- **total:** 98 AC-скриптов + 15 pytest + 6 не-AC шагов `--full`
- **duration:** pytest 2.25 c; suite `catalog-validator` ≈ 5.2 c; `check.sh --full` целиком — в пределах таймаута прогона (по оценке ~1–2 мин, тот же порядок, что в предыдущих отчётах)
- **Итог одной строкой:** полный пак (не subset) прогнан независимо — целевой suite 24/24 (включая новые ac-021…ac-024 и регрессию ac-001…ac-020), pytest 15/15, `--fast` exit 0, `--full` красный ровно по одному **предсуществующему** shellcheck-замечанию SC2034 в файле волны render-killer-linter, к doc-root-discovery отношения не имеющему. Находок-регрессий этой фичи нет. Рекомендация — **merge (GO)**.

---

## Прогон suite → команда → код возврата (честный `$?`)

| # | Проверка | Команда | Код возврата |
|---|---|---|---|
| 1 | Fast gate | `bash scripts/check.sh --fast` | `exit=0` (whitespace OK, json OK, content 76 файлов / 0 ошибок / 0 предупреждений, render ERROR=0) |
| 2 | Целевой suite приёмки (ac-001…ac-024) | `bash tests/gramax/catalog-validator/run.sh` | `exit=0` (24/24) |
| 3 | Unit/pytest | `uv run pytest plugins/gramax/scripts/tests/test_validate_structure.py -v` | `exit=0` (15 passed, 4 subtests passed, 2.25 c) |
| 4 | Full gate (16 шагов) | `bash scripts/check.sh --full` | `exit=1` — ровно один FAIL: `shellcheck SC2034` в `tests/gramax/render-linter/ac-012-dedup-w034.sh:20`; остальные 15 шагов зелёные |
| 5 | Регресс-якорь AC-036 вручную (sanity) | чтение фикстуры `nested-doc-root-discovery/` | root `.doc-root.yaml` валиден, вложенный `examples/project-example/content/.doc-root.yaml` = `title: {{PROJECT_NAME}} — База знаний` (незакавыченный) — до FR-120 валидатор читал только root → exit 0; сейчас → exit ≠ 0 |

---

## Regression analysis

Падений-регрессий этой фичи нет. Единственный красный шаг полного прогона — shellcheck, классифицирован как **pre-existing** (см. «Failed tests (детали)»).

- **`catalog-validator` 20/20 → 24/24** — новые ac-021…ac-024 (AC-036…AC-039) зелёные; существующие ac-001…ac-020 (догфудинг, плейсхолдеры, orphan, ссылки, изображения, W030–W034, `--groups`) не изменили счёт. Подтверждает, что рекурсивный обход не сломал ни один существующий контракт `validate_structure.py`, а граница `in_scope=False` для вложенных root не поломала orphan-учёт (ac-004, ac-024).
- **`render-linter` 21/21** — правки `validate_structure.py` (рекурсивное обнаружение) не затронули демаркацию W034/`<th>` из ADR-0019: W034 по-прежнему молчит по `<th>`; рендер-линтер даёт ERROR — одна находка на дефект.
- **`nauta-integration`, `plugin-contract`, `doc-paths`, `mermaid-adoption`, `writer-consumer-rules`, `link-form-resolver`, `link-form-migration`, `orphan-references`** — все зелёные, не изменялись в этой волне (в diff задачи только `validate_structure.py`, `test_validate_structure.py`, ac-021…ac-024 + фикстуры + content-артефакты SA/BA/Dev).
- **Догфудинг AC-040** — `ac-001-dogfood-clean-exit.sh` PASS: в `content/` ровно один `.doc-root.yaml` (primary), вложенных корней нет; исключения обхода (`tests/**`, `plugins/gramax/scripts/tests/fixtures/**`) защищают прогон на корне репозитория/`plugins/`. Решение 6 ADR-0020 (вариант а) исполнено.

---

## Performance snapshot (опционально, ориентир)

| Метрика | Baseline (до фичи, отчёт 4.4.0) | Текущий | Дельта | Комментарий |
|---|---|---|---|---|
| Suite `catalog-validator` (24 AC) | 20 AC в `--full` (≈ 4–5 c) | 24 AC ≈ 5.2 c | +1 AC счёт, ≈ +1 c | В рамках `--full`, не-блокирующе |
| pytest `test_validate_structure.py` | — | 2.25 c | — | 15 тестов, 4 новых класса |
| Прогон на `content/` (validate-content, 76 файлов) | 72 файла | 76 файлов, 0/0 | +4 файла (новые артефакты фичи) | exit 0 в `--fast` и `--full` |
| `check.sh --full` целиком | ~1–2 мин | в пределах таймаута прогона | — | красный только на pre-existing shellcheck |

NFR-002 (детерминизм) — обход отсортирован, находки по номеру строки (Решение 1 ADR-0020); подтверждено отсутствием flaky-колебаний на двух независимых прогонах suite (прямой + внутри `--full`) — идентичные результаты.

---

## Критерии приёмки (AC-036…AC-040)

| AC | FR | Suite-тест | Результат | Примечание |
|---|---|---|---|---|
| AC-036 | FR-120 рекурсивное обнаружение | ac-021 | PASS | вложенный битый `examples/project-example/content/.doc-root.yaml` обнаружен, путь файла в выводе, exit ≠ 0; регресс-якорь инцидента 2026-08-13 |
| AC-037 | FR-121 типизация полей | ac-022 | PASS | `title: 4.21` / `title: yes` / `title:` (null) / `title: {a: b}` → error с фактическим типом; `title: "4.21"` → чисто |
| AC-038 | FR-122/123 диагностика + подсказка | ac-023 | PASS | сообщение несёт номер строки, слово о плейсхолдере и пример закавычивания; placeholder-находка того же токена подавлена (одна находка на дефект, BR-004) |
| AC-039 | FR-120 ownership / orphan-демаркация | ac-024 | PASS | вложенный root валидируется как отдельный, его статьи не orphan-ы внешнего, ровно одна находка |
| AC-040 | Догфудинг | ac-001 | PASS | в `content/` один root, фикстурные пути исключены из обхода (Решение 6); догфудинг не краснеет |

**Все целевые AC-036…AC-040 — PASS.** Покрытие: 1:1 соответствие AC↔тест; регресс-якорь AC-036 подтверждён фактом фикстуры (валидный root + битый вложенный).

---

## Failed tests (детали)

| Test | Reason category | Probable cause | Action |
|---|---|---|---|
| `tests/gramax/render-linter/ac-012-dedup-w034.sh:20` — `shellcheck SC2034` (`RC=$?` не используется) | **pre-existing** | файл введён и последний раз менялся в `562325e` (feat(gramax): render-killer-linter, v4.4.0, ADR-0019); в diff этой задачи не входит (`git diff --name-only -- tests/gramax/render-linter/` пуст; `git status --short` чист по каталогу). Замечание warning-уровня, exit-поведение скрипта не затрагивает (ac-012 как тест зелёный). Аналогичный класс SC2034/SC2016 задокументирован ранее: `content/lessons-learned.md` (SC2034/SC2016 класс) и `2026-08-13-cross-catalog-retraction-{dev-notes,qa-report}.md` | **не блокер этой фичи**; завести отдельный low-priority фикс (удалить неиспользуемую `RC=$?` или использовать её), не в этой поставке |

---

## Рекомендация

- [x] **merge**
- [ ] block + назад в Dev
- [ ] re-run (flaky)

**Обоснование:** полный пак (не subset) прогнан независимо — целевой suite `catalog-validator` 24/24 (включая новые ac-021…ac-024 и регрессию ac-001…ac-020 без изменения счёта), pytest 15/15 (включая 4 новых класса по FR-120…123), `--fast` exit 0, `--full` 15/16 шагов зелёные. Единственный красный шаг — `shellcheck SC2034` в `tests/gramax/render-linter/ac-012-dedup-w034.sh:20` — классифицирован как **pre-existing**: файл из волны render-killer-linter (коммит `562325e`), этой задачей не трогался, замечание warning-уровня, уже известный задокументированный класс дефекта. Генуинных регрессий FR-120…123 не выявлено ни в одном suite; целевые AC-036…AC-040 закрыты 1:1; регресс-якорь инцидента (битый вложенный `.doc-root.yaml` раньше давал exit 0) подтверждён. Классификация flaky/env не потребовалась: падений, требующих повторных прогонов, нет.
