---
title: "QA Report — ретракция cross-каталожного code:-рецепта (hotfix 4.2.1)"
order: 7
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# QA Report — ретракция cross-каталожного `code:`-рецепта (hotfix 4.2.1)

**Дата прогона:** 2026-08-13
**Ветка/дерево:** `worktree-epic-link-form`, HEAD `bba5d80`, дерево чистое (`git status --porcelain` — пусто)
**Диапазон волны:** `1264a16..bba5d80` — `ce4228d` (проектная фаза), `4a6f8d0` (красный suite приёмки, QA-author), `bba5d80` (реализация Dev)
**Версия на момент прогона:** `plugin.json` / `marketplace.json` — обе `4.2.0` (bump — задача следующей фазы, см. «Ожидаемое незакрытое состояние»)
**Tester:** QA-runner
**Требование:** [Ретракция кросс-каталожного `code:`-рецепта и миграция потребителей](../../30-requirements/2026-08-13-cross-catalog-retraction.md) (AC-001…AC-009)
**ADR:** [0017-cross-catalog-retraction.md](../../00-project/adr/0017-cross-catalog-retraction.md)
**AT-design (qa-author):** [2026-08-13-cross-catalog-retraction-at-design.md](../acceptance/2026-08-13-cross-catalog-retraction-at-design.md)
**Dev notes:** [2026-08-13-cross-catalog-retraction-dev-notes.md](../2026-08-13-cross-catalog-retraction-dev-notes.md)

---

## Summary

| Suite | Команда | Passed | Failed | Skipped | Exit |
|---|---|---|---|---|---|
| `cross-catalog-retraction` (приёмка волны) | `bash tests/gramax/cross-catalog-retraction/run.sh` | 6 | 3 | 0 | `1` |
| `orphan-references` (регрессия) | `bash tests/gramax/orphan-references/run.sh` | 1/1 (гейт) | 0 | 0 | `0` |
| `nauta-integration` (регрессия) | `bash tests/gramax/nauta-integration/run.sh` | 8 | 0 | 0 | `0` |
| `plugin-contract` (регрессия) | `bash tests/gramax/plugin-contract/run.sh` | 7 | 0 | 0 | `0` |
| `doc-paths` (регрессия) | `bash tests/gramax/doc-paths/run.sh` | 2 | 0 | 0 | `0` |
| `catalog-validator` (регрессия) | `bash tests/gramax/catalog-validator/run.sh` | 13 | 0 | 0 | `0` |
| `mermaid-adoption` (регрессия) | `bash tests/gramax/mermaid-adoption/run.sh` | 10 | 0 | 0 | `0` |
| `writer-consumer-rules` (регрессия, точка внимания №1) | `bash tests/gramax/writer-consumer-rules/run.sh` | 11 | 0 | 0 | `0` |
| **Итого (AC/гейты)** | | **58** | **3** | **0** | — |
| Композит `check.sh --fast` | `bash scripts/check.sh --fast` | — | — | — | `0` |
| Композит `check.sh --full` | `bash scripts/check.sh --full` | — | — | — | `0` |

- **passed:** 58 (из них 6 — приёмка волны, 52 — регрессия по 7 существующим suite)
- **failed:** 3 — все три в suite приёмки волны (`AC-006`, `AC-007`, `AC-008`), классифицированы ниже как **ожидаемо-красные**, не дефекты (см. «Ожидаемое незакрытое состояние»)
- **skipped:** 0
- **total:** 61
- **duration:** `check.sh --full` ≈ 14.5 c (`7.51s user 3.24s system 74% cpu 14.516 total`); suite приёмки волны ≈ 1.9 c (`0.91s user 0.48s system 71% cpu 1.945 total`); `check.sh --fast` ≈ 0.84 c
- **Итог одной строкой:** полный пак зелёный за вычетом трёх ожидаемо-красных AC чужой фазы (Tech-writer, FR-102/103); регрессий нет ни на одном из семи существующих suite; все три точки особого внимания проверены явно командами, не предположением — расхождений не найдено. Рекомендация — **передать в release-flow Tech-writer'у**.

---

## Прогон suite → команда → код возврата (честный `$?`, не grep)

Каждая команда прочитана по коду возврата непосредственно после вызова — без `| tail`/`| grep` перед `echo $?` (урок `content/lessons-learned.md`, 2026-08-10/11/13).

| # | Проверка | Команда | Код возврата |
|---|---|---|---|
| 1 | Suite приёмки волны | `bash tests/gramax/cross-catalog-retraction/run.sh` | `exit=1` (6/9) |
| 2 | То же, повтор 2/3 | `bash tests/gramax/cross-catalog-retraction/run.sh` | `exit=1` (6/9), идентично |
| 3 | То же, повтор 3/3 | `bash tests/gramax/cross-catalog-retraction/run.sh` | `exit=1` (6/9), идентично |
| 4 | orphan-references | `bash tests/gramax/orphan-references/run.sh` | `exit=0` |
| 5 | nauta-integration | `bash tests/gramax/nauta-integration/run.sh` | `exit=0` |
| 6 | plugin-contract | `bash tests/gramax/plugin-contract/run.sh` | `exit=0` |
| 7 | doc-paths | `bash tests/gramax/doc-paths/run.sh` | `exit=0` |
| 8 | catalog-validator | `bash tests/gramax/catalog-validator/run.sh` | `exit=0` |
| 9 | mermaid-adoption | `bash tests/gramax/mermaid-adoption/run.sh` | `exit=0` |
| 10 | writer-consumer-rules | `bash tests/gramax/writer-consumer-rules/run.sh` | `exit=0` (**11/11**, было 12 до ретировки `ac-002`) |
| 11 | Fast gate | `bash scripts/check.sh --fast` | `exit=0` |
| 12 | Full gate (агрегатор, включает строки 4–10) | `bash scripts/check.sh --full` | `exit=0` |
| 13 | `git status --porcelain` до и после прогона | — | пусто оба раза — QA-runner не изменил рабочее дерево до записи отчёта |

Три повтора suite'а приёмки волны (строки 1–3) дают идентичный результат (6 passed / 3 failed / exit=1
каждый раз) — красные AC-006/007/008 **стабильны, не flaky**.

Полный непрефильтрованный вывод `--full` прочитан целиком (шаг 12): `shellcheck` →
`OK: shellcheck clean`, все 7 регрессионных suite напечатали `All N AC tests passed.`, финальная
строка `==> RESULT: PASS`.

---

## AC coverage (сверка с at-design qa-author — шаг 1 процесса)

`at-design.md` (ground truth qa-author) заявляет 9 из 9 AC требования покрытыми исполняемым
скриптом (одно, AC-002(в), — частично автоматически + обязательный ручной чек-лист, честно
зафиксировано, не имитируется). Сверка с фактическим состоянием `tests/gramax/
cross-catalog-retraction/`: все 9 `ac-*.sh` присутствуют и исполняются `run.sh`. Пропусков
stubs от qa-author нет — блок-фактора по критерию «тестов нет, а stubs были» не найдено.

| AC | Скрипт | Результат | Класс |
|---|---|---|---|
| AC-001 | `ac-001-doc-root-schema-retracted.sh` | PASS | закрыт Dev |
| AC-002 | `ac-002-skill-md-links-block-consistent.sh` | PASS (a/б автоматически; в — частично авто + ручной чек-лист Dev пройден, см. dev-notes) | закрыт Dev |
| AC-003 | `ac-003-disposition-and-source-untouched.sh` | PASS | regression guard, не тронут |
| AC-004 | `ac-004-corrective-adr-exists-and-links.sh` | PASS | regression guard, ADR-0017 существует и ссылается верно |
| AC-005 | `ac-005-registry-annotations.sh` | PASS (a — Dev внёс аннотацию `40-architecture/_index.md`; б — уже была от PM) | закрыт Dev |
| AC-006 | `ac-006-changelog-migration-guide.sh` | **FAIL** | ожидаемо-красный, Tech-writer |
| AC-007 | `ac-007-plugin-json-version.sh` | **FAIL** | ожидаемо-красный, Tech-writer |
| AC-008 | `ac-008-marketplace-json-sync-decision.sh` | **FAIL** | ожидаемо-красный, Tech-writer |
| AC-009 | `ac-009-check-fast-green.sh` | PASS | regression guard, композит `--fast` |

Независимая проверка позитивных/негативных grep-фраз AC-001/AC-002 вручную (не только через
suite), для честности отчёта:

```
$ grep -ic "декоративн" plugins/gramax/skills/writer/references/doc-root-schema.md
2
$ grep -cF 'Cross-каталожные ссылки через `code`' plugins/gramax/skills/writer/references/doc-root-schema.md
0
$ grep -cF 'Полный рецепт (реальный `code:`)' plugins/gramax/skills/writer/SKILL.md
0
$ grep -n 'Кросс-каталож' plugins/gramax/skills/writer/SKILL.md
213:- Кросс-каталожные: `` `other-catalog/path/to/file.md` `` — inline code, не markdown-ссылка
```

Буллет `SKILL.md:213` больше не показывает markdown-форму — использует тот же код-спан-пример,
что и абзац ниже (AC-002(в), закрывает семантическое противоречие с первого коммита плагина).
Ручной чек-лист AC-002(в) (`README.md` suite'а → «Ручная проверка (AC-002в)») выполнен Dev'ом
(зафиксировано в dev-notes) — QA-runner повторно прочитал блок «## Ссылки» целиком и подтверждает
тот же вывод: единственные примеры `[X](Y)` в блоке — легитимные ❌-иллюстрации, прозы,
рекомендующей markdown-форму для кросс-каталожных ссылок, нет.

AC-003/AC-008 используют `BASELINE_COMMIT="ce4228d"`, зафиксированный QA-author в
`lib/baseline-commit.sh` **до** начала правок Dev (закрывает открытый вопрос №5 требования) —
не диапазон всей волны `1264a16..bba5d80`. Разница объяснима и легитимна: `ce4228d` — коммит,
которым созданы оба ADR/требования этой волны и правка реестра ADR, `1264a16` — предыдущий merge
в `main`, не относящийся к содержанию этой волны. Проверено независимо:

```
$ git diff --quiet ce4228d..HEAD -- content/40-architecture/2026-08-11-writer-rules-disposition.md content/30-requirements/2026-08-11-writer-consumer-rules.md; echo "exit=$?"
exit=0
```

Диспозиция и исходное требование-первоисточник побайтово не тронуты — AC-003 подтверждён
независимо от суммарного счёта suite'а.

---

## Регрессионный анализ

### Точка внимания №1 — `tests/gramax/writer-consumer-rules/` — ретировка `ac-002`, ожидание 11/11

**Подтверждено:** `bash tests/gramax/writer-consumer-rules/run.sh` → `Passed: 11, Failed: 0,
exit=0`. Было 12 живых скриптов до волны (см. `2026-08-12-wave-4.2.0-qa-report.md`), стало 11 —
ровно на один меньше, соответствует заявленной ретировке, соседние ассерты не задеты (все
оставшиеся 11 — PASS, включая три regression guard'а AC-001/AC-011/AC-012, которые ретировка
не трогала).

**README suite'а** (`tests/gramax/writer-consumer-rules/README.md`, раздел «Ретировка AC-002
(2026-08-13, ADR-0017)») описывает ретировку полно: что проверялось, почему это ретировка, а не
«ещё не реализовано», воспроизводимое измерение (co-occurrence трёх сигналов совпадает и после
правки — по историческому объяснению, не по рабочему рецепту), кто санкционировал (ADR-0017 +
прямое поручение PM), процедура по ADR-0011 Решение 2, файл удалён `git rm` (не перемещён в
`archive/`, обоснование дано). Заголовочная таблица suite'а и `run.sh`-комментарий синхронно
отражают «11, не 12». Формально верно и полно — соответствует контракту находки, предсказанной
заранее в `at-design.md` cross-catalog-retraction (раздел «Находка вне периметра этой задачи»).

**Вывод:** регрессии нет, документация ретировки полна. Замечаний нет.

### Точка внимания №2 — `tests/gramax/doc-paths/` — whole-file запись allowlist на `2026-08-13-link-form-corpus-audit.md`

**Подтверждено:** `ac-002-stale-allowlist-detected.sh` (freshness-проверка) не деградировала —
работает на изолированной фикстуре `fixtures/stale-allowlist/`, не на живом `allowlist.txt`,
новая запись физически не может повлиять на этот тест. Прогнан отдельно: PASS.

Проверено по существу (не только по факту, что тест зелёный), что новая whole-file запись не
маскирует реальные протухшие указатели:
- Новый файл `content/10-domain/research/2026-08-13-link-form-corpus-audit.md` — сплошной аудит
  указателей корпуса; все вхождения `docs/`-паттерна в нём проверены построчно
  (`grep -nE '<DOC_PATHS_PATTERN>' ...`) — 100% находятся внутри таблиц находок (столбец
  «существует: нет», адрес источника) или во вводном тексте, описывающем класс проблемы (строки
  481, 584) — ни одного случая «приглашения перейти» по нерабочему пути, все — свидетельства
  прогона с классификацией, тот же класс записи, что уже принят в allowlist для предыдущих
  QA-отчётов (`2026-05-11-remove-diagram-skills-qa-report.md` и др.).
- Механизм whole-file записи (`lib/scan.sh`) по конструкции не делает построчный freshness-пиннинг
  (это осознанное решение ADR-0011 Решение 4, не пробел этой волны) — сопоставление идёт по
  точному имени файла (`"$p" = "$file"`), поэтому запись физически не может замаскировать
  находку в ДРУГОМ файле; риск ограничен только тем же файлом, а его содержимое проверено выше.
- `ac-001-no-stale-pointers.sh` (проверка живого `content/`) — PASS, 0 нерабочих указателей вне
  allowlist.

**Вывод:** регрессии нет, новая запись обоснована по содержанию и не расширяет маскирующую
поверхность на другие файлы. Замечаний нет.

### Точка внимания №3 — область видимости shellcheck (`git ls-files`) — до/после `git add`

**Подтверждено явно, не предположением:** дерево на момент прогона чистое
(`git status --porcelain` — пусто), HEAD = `bba5d80`, все файлы закоммичены. `git ls-files
'*.sh'` включает все 12 файлов `tests/gramax/cross-catalog-retraction/**` (проверено отдельной
командой). `shellcheck -x -P SCRIPTDIR` на них напрямую — `exit=0`. `check.sh --full` подтверждает
`OK: shellcheck clean`. Расхождения между «до `git add`» и «после» сегодня действительно нет —
уже нечего добавлять, дерево целиком отслеживается.

**Находка при более глубокой проверке (не входит в саму точку внимания №3, но обнаружена при её
проверке):** `content/60-implementation/2026-08-13-cross-catalog-retraction-dev-notes.md`,
раздел «3. `bash scripts/check.sh --full` был красным ДО начала этой Dev-задачи — не регрессия
этой правки» утверждает, что «diff между прогоном `--full` до и после правок Dev показал ровно
одно отличие — счётчик `writer-consumer-rules` (12→11) …, сам `shellcheck`-блок и его причина
идентичны». Это не совпадает с фактическим диапазоном изменений коммита `bba5d80` (сам Dev):

```
$ git diff 4a6f8d0..bba5d80 --stat -- tests/gramax/cross-catalog-retraction/
 .../ac-001-doc-root-schema-retracted.sh          | 1 +
 .../ac-002-skill-md-links-block-consistent.sh    | 1 +
 tests/gramax/cross-catalog-retraction/lib/baseline-commit.sh | 1 +
 3 files changed, 3 insertions(+)
```

Дев добавил ровно 3 точечных `# shellcheck disable=SC2016`/`SC2034` с построчным обоснованием —
и это единственная причина, по которой `shellcheck` сегодня зелёный (проверено: `shellcheck` на
версиях этих трёх файлов из коммита `4a6f8d0` без этих аннотаций даёт `exit=1`, 2×`SC2016` +
1×`SC2034` — ровно то, что dev-notes описывают как «дефект не в периметре Dev»). Сам коммит
`bba5d80` (сообщение коммита) правильно раскрывает это изменение («Shellcheck-аннотации в стабах
приёмки: три точечных disable...») — расхождение только в тексте отдельного артефакта dev-notes,
который, по всей видимости, зафиксировал промежуточное измерение ДО того, как аннотации были
добавлены в тот же коммит, и не был обновлён перед сдачей. Фактическое состояние репозитория —
корректное и зелёное; это не регрессия и не блокер, а неточность нарратива одного артефакта
документации.

**Вывод по точке внимания №3:** расхождения по существу (области видимости shellcheck) нет —
дерево чистое, гейт зелёный, воспроизводимо. Отдельно — найдена и зафиксирована неточность в
`dev-notes` (не влияет на код/тесты, не блокирует передачу), рекомендуется Dev поправить
формулировку раздела 3 при следующей правке этого файла для точности будущих читателей.

---

## Ожидаемое незакрытое состояние (не дефект)

Suite приёмки волны даёт устойчиво **6 passed / 3 failed**, `exit=1`, при трёх независимых
прогонах подряд. Три красных AC:

| AC | Что проверяет | Почему красный сегодня | Кто закрывает |
|---|---|---|---|
| AC-006 | Секция `## 4.2.1` в `CHANGELOG.md` с migration guide (FR-100/101) | Секции нет вовсе — CHANGELOG не тронут этой Dev-фазой | Tech-writer (FR-100, ADR-0017 Решение 3 — точный текст уже зафиксирован, подставить дату релиза) |
| AC-007 | `jq -r .version plugin.json` == `4.2.1` | `plugin.json` несёт `4.2.0` | Tech-writer (FR-102) |
| AC-008 | `marketplace.json` синхронизирован ИЛИ отложен явным решением ADR | `marketplace.json` == `4.2.0` (ADR уже авторизует синхронный bump, ветка «б», но сам bump не внесён) | Tech-writer (FR-103, ADR-0017 Решение 3 ветка «б») |

**Обоснование, почему это не провал волны:** FR-102 требования и ADR-0017 Решение 3 п.4 явно
относят bump версий и CHANGELOG-запись к release-flow Tech-writer, выполняемому **после** Dev и
QA-runner — по прецеденту ADR-0006. Dev-notes подтверждают: «Периметр этой поставки Dev: пункты
1–3 и 7 «Брифа для Dev» ... Пункты 4–6 (CHANGELOG, plugin.json, marketplace.json) — территория
Tech-writer, сознательно не тронуты». At-design qa-author заранее зафиксировал эти три AC как
«красные до фазы Tech-writer» (README suite'а, таблица «Стартовое состояние»). Точные тексты
CHANGELOG и решение по `marketplace.json` уже прописаны в ADR-0017 Решение 3 — Tech-writer не
принимает новых архитектурных решений, только подставляет фактическую дату релиза и вносит уже
согласованный текст.

Это состояние явно отделено от реальных дефектов (раздел выше — регрессионный анализ по трём
точкам внимания, там дефектов не найдено).

---

## Failed tests (детали)

| Test | Reason category | Probable cause | Action |
|---|---|---|---|
| `tests/gramax/cross-catalog-retraction/ac-006-changelog-migration-guide.sh` | new / expected-incomplete (не дефект Dev) | Tech-writer-фаза ещё не наступила — CHANGELOG правится после Dev+QA по ADR-0006/ADR-0017 | не блокирует; передать Tech-writer, текст уже готов в ADR-0017 Решение 3 |
| `tests/gramax/cross-catalog-retraction/ac-007-plugin-json-version.sh` | new / expected-incomplete | Bump `plugin.json` — задача Tech-writer (FR-102) | не блокирует; передать Tech-writer |
| `tests/gramax/cross-catalog-retraction/ac-008-marketplace-json-sync-decision.sh` | new / expected-incomplete | Bump `marketplace.json` — задача Tech-writer, ADR-0017 уже авторизует ветку «б» (FR-103) | не блокирует; передать Tech-writer |

Ни один failed test не относится к категориям `regression`/`flaky`/`env` — все три однозначно
`new`/expected-incomplete, обоснование зафиксировано в требовании (FR-102/103) и ADR-0017 Решение
3 п.4, не является предположением QA-runner.

---

## Performance snapshot (контекст, не NFR-гейт)

Требование не вводит NFR по производительности (NFR-001…004 — объём материала, обратная
совместимость, трассируемость, язык). Snapshot ниже — для контекста относительно предыдущего
QA-отчёта, не проверка AC:

| Метрика | Baseline (`2026-08-12-wave-4.2.0-qa-report.md`, 7 suite/52 AC) | Текущий (7 регрессионных suite/51 AC, `writer-consumer-rules` −1 после ретировки) | Дельта |
|---|---|---|---|
| `check.sh --full`, real time | ≈ 11.6 c | ≈ 14.5 c | +2.9 c |
| `check.sh --fast`, real time | ≈ 0.68 c | ≈ 0.84 c | +0.16 c |
| Живых AC в `--full` | 52 | 51 (−1, ретировка `ac-002`) | −1 AC, состав suite не менялся |

Рост времени `--full`/`--fast` — в пределах шума окружения (число живых suite и их состав не
изменились, кроме −1 AC от ретировки), не связан с продуктовыми изменениями волны; suite
приёмки (`cross-catalog-retraction`) не подключён к `check.sh` (сознательное решение qa-author,
см. README suite'а «Подключение к scripts/check.sh»), поэтому не входит в это сравнение.

---

## Рекомендация

- [x] передавать в release-flow Tech-writer'у
- [ ] блокировать (назад в Dev)
- [ ] перепрогнать (flaky)

**Обоснование:** полный пак прогнан (не subset) — 7 существующих регрессионных suite (52 AC до
волны → 51 AC после легитимной ретировки одного, все зелёные, включая точку внимания №1 — ровно
11/11) плюс suite приёмки волны (6/9 AC зелёные, 3/9 стабильно красные при 3 независимых
прогонах). Три красных AC (AC-006/007/008) явно и заранее классифицированы требованием (FR-102),
ADR-0017 (Решение 3 п.4) и at-design qa-author как принадлежащие следующей фазе (Tech-writer,
release-flow), не как дефект реализации Dev — это ожидаемое незакрытое состояние, не провал
волны. Обе точки внимания №2 и №3 проверены по существу командами, не предположением, — расхождений
не найдено; единственная находка (неточность одного абзаца в `dev-notes`, не влияющая на код) —
документационная, не блокирующая, зафиксирована выше с рекомендацией Dev поправить формулировку.
`check.sh --fast` и `--full` зелёные (`exit=0`) на итоговом дереве. Блокеров для передачи в
release-flow Tech-writer'у не найдено.

**Передача:** Tech-writer выполняет FR-100 (CHANGELOG), FR-102 (`plugin.json` → `4.2.1`), FR-103
ветка «б» (`marketplace.json` → `4.2.1`, разрешено ADR-0017 Решение 3) — точные тексты уже
зафиксированы ADR-0017 Решение 3, подставить только фактическую дату релиза. После bump — повторный
прогон `tests/gramax/cross-catalog-retraction/run.sh` ожидаемо даёт `9/9`, `exit=0`; это следующий
QA-цикл, не часть этого отчёта.

---

## Постпроверка

После записи этого отчёта и добавления строки в `test-reports/_index.md`:

```
$ bash scripts/check.sh --fast; echo "exit=$?"
exit=0
```

`git status --porcelain` до и после записи артефактов QA-runner — единственные изменения:
этот файл и строка в `_index.md` (правки кода продукта/тестов не вносились, по красной линии
роли QA-runner).
