---
title: "QA Report — прибор рендер-проб Playwright: первый --full после подключения сюиты render-quality (шаг 18); shellcheck SC2034×2 + SC2059×3, класс NEW, вердикт fix-first"
order: 18
status: draft
date: 2026-11-21
plugin: gramax
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Draft]
  - name: Плагин
    value: [gramax]
---

# QA Report — прибор рендер-проб Playwright: первый --full после подключения сюиты render-quality (шаг 18); shellcheck SC2034×2 + SC2059×3, класс NEW, вердикт fix-first

| Поле | Значение |
|---|---|
| Дата прогона | 2026-11-21 |
| Прогон | координаторский `bash scripts/check.sh --full`, лог `/tmp/full-gate-render-quality.log` (817 строк, прочитан целиком) — авторитетный источник цифр этого отчёта |
| Дерево | `main`, HEAD `36b9863` (dev-коммит: каркас `scripts/render-quality` + шаг 18 в `check-gramax.sh --full`), дерево чисто; сьюты рождены коммитом qa-author `cf77384` |
| Tester | QA-runner — классификация отказа полного прогона; код и тесты сессией не правились |
| Требование | `docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md` (AC-104…AC-119; в этом прогоне существенны AC-113, AC-118, AC-119) |
| Сьюта | `tests/gramax/render-quality/` — 12 офлайн-стабов + агрегатор `run.sh` + живой прогон прибора |
| Итог прогона | `check.sh --full` rc=1; единственный отказ — шаг `shellcheck`; `check.sh --fast` в хвосте того же прогона — PASS |

**Опоры:** `tests/gramax/render-quality/run.sh`, `tests/gramax/render-quality/ac-109-reindex-states.sh`, `tests/gramax/render-quality/ac-111-screenshots.sh`, `docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md`, `scripts/check-gramax.sh`

---

## Summary

**Вердикт: fix-first (block + назад в Dev).** Полный гейт упал ровно на одном шаге — `shellcheck` внутри `scripts/gate-gramax-full.sh`: пять находок в трёх файлах сьюты render-quality (SC2034 ×2 — capture-and-unused, SC2059 ×3 — цветовые переменные в формате printf). Все шаги ПОСЛЕ отказавшего продолжались и зелёные: сьюта render-quality — 12/12 стабов + живой прогон прибора 17/17 `verdict: PASS`; все прочие сьюты --full зелёные (AC-119 соблюдён); хвостовой `--fast` — PASS. Отказ — чисто lint-дефект текущего набора изменений: три файла рождены в `cf77384` и впервые попали под скан shellcheck в этом, первом после подключения шага 18, прогоне --full (`--fast` shellcheck не исполняет). Классификация всех пяти находок: **NEW**, владелец — Dev, фиксы минимальные lint-only без касания ассертов и rc-логики.

| Показатель | Значение |
|---|---|
| Шагов в прогоне | 33 (13 внешних nauta-гейтов + 20 шагов `gate-gramax-full.sh`; затем `gate-gramax-fast.sh`) |
| Отказов | 1 (шаг `shellcheck`) |
| Класс отказа | NEW (5 находок: SC2034 ×2, SC2059 ×3) |
| Сьюта render-quality в этом же прогоне | 12/12 стабов PASS + live probe `fixtures=17 match=17 divergence=0`, `verdict: PASS` |
| AC-118 (`--fast` изоляция) | подтверждена: хвостовой `--fast` — `RESULT: PASS`; стаб `ac-118` — PASS (мой прогон, rc=0) |
| AC-113 (шаг только в --full) | подтверждена: шаг 18 исполнен в --full; в шагах --fast сюиты нет; стаб `ac-113` — PASS (мой прогон, rc=0) |
| Итог одной строкой | функциональная приёмка сьюты зелёная (включая живой прогон на тёплой цели), merge блокирует исключительно lint-долг трёх файлов сьюты — минимальный фикс назван, после него требуется повторный --full |

---

## Классификация отказов (таксономия дома: regression / new / flaky / env)

| # | Файл:строка | Код shellcheck | Severity | Класс | Владелец | Минимальный фикс (lint-only) |
|---|---|---|---|---|---|---|
| 1 | `tests/gramax/render-quality/ac-109-reindex-states.sh:82` | SC2034 (warning) — `OUT appears unused` | warning→блок | NEW | Dev | `OUT="$(bash "$PROBE" … 2>&1)"` → `bash "$PROBE" … >/dev/null 2>&1`; строка `RC=$?` не трогается |
| 2 | `tests/gramax/render-quality/ac-111-screenshots.sh:83` | SC2034 (warning) — тот же узор (перенос строки) | warning→блок | NEW | Dev | то же: `bash "$PROBE" … --report "$TMP/results/report.md" >/dev/null 2>&1`; `RC=$?` не трогается |
| 3 | `tests/gramax/render-quality/run.sh:66` | SC2059 (info) — переменные в формате printf | info→блок | NEW | Dev | `printf '%s\n' "${GREEN}OK: live probe green${NC}"` |
| 4 | `tests/gramax/render-quality/run.sh:68` | SC2059 (info) — включая `${live_rc}` в формате | info→блок | NEW | Dev | `printf '%s\n' "${RED}FAIL: live probe rc=${live_rc} (rc=1 — расхождения, rc=2 — именованный отказ окружения; D8)${NC}"` |
| 5 | `tests/gramax/render-quality/run.sh:72` | SC2059 (info) | info→блок | NEW | Dev | `printf '%s\n' "${RED}FAIL: live probe — вход scripts/render-quality/probe.sh отсутствует (каркас прибора не реализован; дизайн, Решение 5)${NC}"` |

Строка severity «→блок»: политика шага — любая находка shellcheck по проектным `.sh` блокирует (`scripts/check-gramax.sh`, комментарий шага 3: «Проектные .sh … их находки остаются блокирующими»; исключения `-e SC1125/SC2001/SC2016/SC2086` касаются только payload-файлов nauta и на эти файлы не распространяются).

### Доказательства класса NEW

- **Рождение в этом наборе изменений:** `git log --diff-filter=A` по каждому из трёх файлов — единственный коммит `cf77384` (qa-author, 2026-11-21); dev-коммит `36b9863` эти файлы не модифицировал (полный `git log` каждого — одна запись).
- **Первый скан:** shellcheck исполняется только в `--full` (заголовок `scripts/check-gramax.sh`, строка 9: «--full: --fast + shellcheck …»); это первый --full после подключения шага 18 — файлы под shellcheck не попадали ни разу.
- **Не regression:** не сломано ни одно поведение, бывшее зелёным — эти файлы никогда не проходили shellcheck (первый скан); прочие отслеживаемые `.sh` (скан — все `git ls-files '*.sh'` минус `tests/gramax/archive/`) чисты, иначе шаг назвал бы их.
- **Не flaky:** детерминировано — прогон координатора rc=1; мой независимый повтор точной команды гейта (`shellcheck -e SC1125 -e SC2001 -e SC2016 -e SC2086 -x -P SCRIPTDIR` на трёх файлах) — rc=1 с теми же пятью находками. 2 из 2 одинаковых.
- **Не env:** shellcheck установлен и работает по контракту; находки — реальные дефекты кода сьюты, а не шум окружения (живой прогон прибора в том же логе зелёный — окружение тёплое).

---

## Регрессионный анализ

Регрессий не найдено. Опора вывода — тот же лог прогона:

- **Соседние сьюты не сужены** (AC-119): nauta-integration 8/8, plugin-contract 7/7, catalog-validator 36/36, mermaid-adoption 10/10, writer-consumer-rules 11/11, link-form-resolver 8/8, link-form-migration 7/7, export-skill 10/10, plantuml-bpmn 12/12, writer-sync-470 24/24, writer-tail-480 — зелёный (7 PASS), render-linter 21/21 — все после отказавшего шага, все PASS.
- **Regression-guard'ы живы:** catalog-validator `ac-027` (regression guard drawio) PASS; render-linter `ac-012/ac-019/ac-021` PASS; nauta-integration `ac-002/ac-008` (делегация гейтов через projectGates) PASS.
- **Fast-путь не тронут:** хвостовой `gate-gramax-fast.sh` — `RESULT: PASS` (шаги whitespace/json/content/render, render-quality в списке нет); мои повторные прогоны стабов `ac-113` и `ac-118` — rc=0 и rc=0.
- **Маскировки отказом нет:** шаги гейта исполняются fail-soft — после `FAIL: shellcheck issues` всё продолжилось до `RESULT: FAIL`, поэтому финальный FAIL не прячет поздних отказов (таблица ниже — доказательство).

---

## Статус шагов всего прогона (полная таблица)

Внешний контур (nauta-гейты до projectGates) — все зелёные:

| # | Проверка | Статус | Примечание |
|---|---|---|---|
| 1 | check-hooks-path.sh | OK | hooksPath сверено |
| 2 | check-branch-discipline.py | OK | профиль не объявлен — undetermined (шум, не отказ) |
| 3 | secret-scan-tree | OK | 709 файлов |
| 4 | validate-content.py | OK | Errors 0 / Warnings 6 — досинтезные TPL-69 (`0020-doc-root…`, `2026-05-*`, `2026-08-*`) |
| 5 | validate-profile.py | OK | профилей нет |
| 6 | check-content-actuality.py | мягкий код 1 | объявлен soft на вызове (ADR-007 Д1); 88 «неопределим» — старые статьи без маркера |
| 7 | check-subprocess-encoding.py | OK | 0 findings |
| 8 | check-ratchet.py | OK | громкий ноль |
| 9 | measure-session-cost.py | мягкий код 3 | NOT-MEASURED — состояние прогона, не вердикт (объявлено soft) |
| 10 | check-status-drift.py | OK | 0 drift |
| 11 | id-check.sh | OK | 6 реестров чисто |
| 12 | test-check-id.sh | OK | PASS=24 FAIL=0 |
| 13 | test-validate-content.sh | OK | PASS=24 FAIL=0 |

`scripts/gate-gramax-full.sh --full`:

| # | Шаг | Статус | Примечание |
|---|---|---|---|
| 14 | whitespace | OK | |
| 15 | json | OK | |
| 16 | content | OK | Errors 0 / Warnings 6 |
| 17 | render | OK | файлов=109, ERROR=0 |
| 18 | **shellcheck** | **FAIL** | **единственный отказ прогона** — 2×SC2034 + 3×SC2059, см. классификацию |
| 19 | submodule status | OK | in sync |
| 20 | orphan-references | OK | clean |
| 21 | nauta-integration | OK | 8/8 |
| 22 | plugin-contract | OK | 7/7 |
| 23 | catalog-validator | OK | 36/36 |
| 24 | mermaid-adoption | OK | 10/10 |
| 25 | writer-consumer-rules | OK | 11/11 |
| 26 | link-form-resolver | OK | 8/8 |
| 27 | link-form-migration | OK | 7/7 |
| 28 | export-skill | OK | 10/10 |
| 29 | plantuml-bpmn | OK | 12/12 |
| 30 | writer-sync-470 | OK | 24/24 |
| 31 | writer-tail-480 | OK | 7 PASS |
| 32 | render-linter | OK | 21/21 |
| 33 | render-quality (шаг 18 по нумерации `check-gramax.sh`) | OK | 12/12 стабов; live probe: `fixtures=17 match=17 divergence=0`, `verdict: PASS`; две kill-группы STABLE_5XX с нотой переиндексации — ожидаемая семантика AC-109 |
| — | RESULT | **FAIL** | FAILED=1 целиком от шага 18 таблицы (shellcheck); шаги после отказа исполнялись |

`scripts/gate-gramax-fast.sh --fast` (исполнен после красного full-гейта): whitespace OK, json OK, content OK, render OK → `RESULT: PASS`. Итог обёртки: `✗ check.sh --full — FAILED`, rc=1.

**Ответ на вопрос брифа (маскировка):** ничего после shellcheck не падало — шаги 19–33 зелёные, оба финальных FAIL-заголовка (`RESULT: FAIL`, `✗ check.sh --full — FAILED`) объясняются единственным отказом шага 18.

---

## Failed tests (детали)

Единственный отказ — шаг `shellcheck` (полное название по логу: `FAIL: shellcheck issues`). Пять находок, все — в коде сьюты render-quality:

| Находка | Цитата | Почему срабатывает | Контракт фикса |
|---|---|---|---|
| SC2034 в `ac-109…:82` | `OUT="$(bash "$PROBE" --config … --report "$TMP/report.md" 2>&1)"` | переменная `OUT` нигде не читается; оба потока фактически отбрасываются, rc забирается следующей строкой `RC=$?` | заменить capture на discard-редирект `bash "$PROBE" … >/dev/null 2>&1` — наблюдаемое поведение байт-в-байт то же (stdout+stderr отбрасывались и до фикса), `RC=$?` остаётся следующей строкой |
| SC2034 в `ac-111…:83` | тот же узор с переносом (`--report "$TMP/results/report.md" 2>&1)")` | идентично | идентично |
| SC2059 в `run.sh:66` | `printf "${GREEN}OK: live probe green${NC}\n"` | цветовые переменные в формате printf — опасно: `%`/`\` в значениях интерпретировались бы как директивы | `printf '%s\n' "${GREEN}OK: live probe green${NC}"` — переменные в аргументы; вывод тот же (литерал не содержит `%`) |
| SC2059 в `run.sh:68` | `printf "${RED}FAIL: live probe rc=${live_rc} (rc=1 — расхождения, rc=2 — именованный отказ окружения; D8)${NC}\n"` | то же + `${live_rc}` в формате | `printf '%s\n' "${RED}FAIL: live probe rc=${live_rc} (…; D8)${NC}"` — раскрытие `${live_rc}` переезжает в аргумент, байты вывода те же |
| SC2059 в `run.sh:72` | `printf "${RED}FAIL: live probe — вход scripts/render-quality/probe.sh отсутствует (…)${NC}\n"` | то же | `printf '%s\n' "${RED}FAIL: … (…)${NC}"` |

#### Полнота находок (почему ровно пять)

`run.sh` содержит ещё пять printf того же стиля «переменная в формате» (строки 34, 38, 50, 51, 79) — но в каждой из них формат несёт директиву `%d`/`%s` с соответствующим аргументом. Эмпирическая проверка (мини-фикстуры в `/tmp`, тот же shellcheck): вариант с директивой и аргументом SC2059 не даёт, вариант без директив (`printf "${GREEN}текст${NC}\n"`) — даёт. Именно поэтому flagged-набор — ровно строки 66/68/72, и именно тот же узор у sibling-агрегаторов (`render-linter/run.sh`, `nauta-integration/run.sh`) проходит гейт годами. Находки полны, скрытых нет.

#### Границы фикса (обязательство для Dev)

- Исправляются только формы вывода и discard-capture: **ни один ассерт, ни одно ожидание rc, ни `set -u -o pipefail` не меняются** — все пять строк не участвуют в логике проверок (66/68/72 — чистый вывод; 82/83 в ac-109 и 83–85 в ac-111 — capture, чей результат не читается, при `RC=$?` рядом).
- Осторожно с вариантом «оставить capture, добавить `: "$OUT"`»: строку намерения ставить **строго после** `RC=$?` — если вставить между присваиванием и `RC=$?`, `RC=$?` начнёт читать rc от `:` и rc-семантика ассерта ac-109/ac-111 сломается. Рекомендованный вариант — discard-редирект, он тривиально эквивалентен.
- Пять непомеченных printf с директивами чинить **не обязательно** (гейт их не флагает); унификация стиля — опциональная уборка, не условие зелёности.

---

## Влияние фикса на вердикт сьюты и AC-113/AC-118 — не затрагивается

- **Вердикт сьюты PASS не изменится:** фиксы меняют только то, как отбрасываются потоки и собирается строка вывода; вердикт агрегатора определяется счётчиком стабов и `live_rc` (строки 75–77 `run.sh`) — до них фикс не дотягивается. Ассерты ac-109 читают `RC` и файл отчёта, не `OUT`; ассерты ac-111 — rc, файлы скриншотов и отчёт.
- **AC-118 (`--fast` изоляция, NFR-078):** подтверждена независимо от фикса — в логе хвостовой `--fast` дал `RESULT: PASS` без шага render-quality, мой повтор стаба `ac-118-fast-isolation.sh` — rc=0. Фикс внутри файлов сьюты состав шагов --fast не меняет.
- **AC-113 (регистрация шагом --full после зелёного):** подтверждена — шаг 18 исполнился в --full (12/12 + live probe), в --fast-пути сюиты нет, стаб `ac-113-full-only.sh` в моём прогоне — rc=0. Требование «после зелёного прогона qa-runner по TDD-цепочке» исполняется этим отчётом: классификация произведена, зелёность сьюты в --full зафиксирована логом.
- **AC-119:** все прочие сьюты --full зелёные в том же прогоне (таблица шагов).

---

## Контекст прогона (наблюдения вне отказов — не блокируют)

1. **Окружение живого прогона тёплое:** probe шёл на `http://127.0.0.1:8641` (конфиг `scripts/render-quality/render-target.local.json`), 10 фикстур отдали 200, 7 — ожидаемые 500 (kill-группы) с нотой «кандидат на переиндексацию» — семантика AC-109 в живом виде. Окно gram.ax (NFR-080) не устанавливалось — кодом не кодируется, стаб `ac-109` это отдельно проверяет.
2. **Fail-soft агрегация гейта:** красный шаг не останавливает --full — это позволило в одном прогоне увидеть и отказ shellcheck, и зелёность сьюты/прочих сьют. Для будущих классификаций: финальный `RESULT: FAIL` обязан раскладываться по шагам, иначе маскирует.
3. **Оба мягких кода внешнего контура** (actuality код 1, session-cost код 3) — объявленно-мягкие на вызове и предсуществующие; к этому набору изменений отношения не имеют.

---

## Рекомендация

- [x] **fix-first (block + назад в Dev)** — единственный отказ класса NEW; merge остаётся заблокированным до фикса и зелёного повторного `--full` (красная линия дома: merge не принимается, пока отказ не получил подтверждённый класс flaky/env с исправленной инфраструктурой; NEW таким классом не является)
- [ ] accept
- [ ] re-run (flaky)

**Обоснование:** функциональная приёмка сьюты зелёная — 12/12 стабов и живой прогон 17/17 в авторитетном логе, изоляция --fast (AC-118) и регистрация шага (AC-113) подтверждены логом и моими повторами стабов; соседние сьюты не сужены (AC-119). Блокирует исключительно lint-долг трёх файлов сессии qa-author, впервые увиденный первым --full сканом. Содержательная работа Dev и qa-author не ставится под сомнение: дефекты — в формах вывода.

**Передача (handoff для Dev, дословно):**

```text
Handoff → Dev: shellcheck SC2034×2 + SC2059×3 — класс NEW (файлы рождены cf77384, первый
--full-скан), lint-only, ассерты/rc не менять:
1) tests/gramax/render-quality/ac-109-reindex-states.sh:82 и
   tests/gramax/render-quality/ac-111-screenshots.sh:83 — OUT="$(bash "$PROBE" … 2>&1)"
   → bash "$PROBE" … >/dev/null 2>&1 (строку RC=$? не трогать; альтернатива ": $OUT" —
   СТРОГО после RC=$?);
2) tests/gramax/render-quality/run.sh:66,68,72 — printf "${COLOR}…${NC}\n" →
   printf '%s\n' "${COLOR}…${NC}" (переменные, включая ${live_rc}, — в аргументы).
После фикса: shellcheck -e SC1125 -e SC2001 -e SC2016 -e SC2086 -x -P SCRIPTDIR на трёх
файлах — rc=0; повторный bash scripts/check.sh --full — зелёный; повторный bash
scripts/check.sh --fast — остаётся rc=0 (AC-118 не затрагивается).
```

**Код/тесты этой QA-сессией не менялись** (красная линия роли); артефакты сессии — этот отчёт, строка регистрации в `docs/60-implementation/test-reports/_index.md` и точечные прогоны: shellcheck по трём названным файлам, стабы `ac-113`/`ac-118`.

---

## Постпроверка

После записи отчёта и строки регистрации исполнен `bash scripts/check.sh --fast`:

```text
$ bash scripts/check.sh --fast; echo "GATE_RC=$?"
GATE_RC=0     # Errors: 0 | Warnings: 6 — все шесть досинтезные TPL-69 (набор не изменился),
#             # собственных находок нет; render: файлов=110, ERROR=0; RESULT: PASS
# check-content-actuality об отчёте: «актуален — опоры разрешились (5)»
```

Окна C1/C10 нет: строка регистрации в `_index.md` внесена той же сессией, гейт остался rc=0.
