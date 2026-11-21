---
title: "QA Report qa-057 — волна-2 render-quality: полный гейт --full на f8af038; единственный красный — ac-128 нога (д), артефакт закрытия волны ещё не написан; вердикт — закрытие без возврата в Dev"
order: 19
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

# QA Report qa-057 — волна-2 render-quality: полный гейт --full на f8af038; единственный красный — ac-128 нога (д), артефакт закрытия волны ещё не написан; вердикт — закрытие без возврата в Dev

| Поле | Значение |
|---|---|
| Дата прогона | 2026-11-21 (ночь; mtime лога 23:34) |
| Прогон | координаторский `bash scripts/check.sh --full` по всему корпусу, лог `/tmp/wave2-full-gate.log` (785 строк, прочитан целиком) — авторитетный источник цифр отчёта |
| Дерево | `main`, HEAD `f8af038` (tier1-ожидания семи некалиброванных ног волны-1 pass → any), несохранённое дополнение только `docs/lessons-learned.md` (preflight: 1 изменённый файл — брифу соответствует) |
| Tester | QA-runner — классификация отказа полного прогона; код и тесты сессией не правились |
| Требование | `docs/30-requirements/2026-11-21-render-quality-wave2-requirements.md` (FR-199…FR-207, AC-120…AC-128, NFR-083) |
| Сьюта | `tests/gramax/render-quality/` — 18 офлайн-стабов + живой прогон прибора на настроенной цели |
| Итог прогона | `check.sh --full` rc=1; единственный отказ — стаб `ac-128` (нога д); хвостовой `check.sh --fast` — PASS |

**Опоры:** `tests/gramax/render-quality/ac-128-docs-closure.sh`, `tests/gramax/render-quality/README.md`, `docs/30-requirements/2026-11-21-render-quality-wave2-requirements.md`, `docs/60-implementation/acceptance/2026-11-21-render-quality-wave2-at-design.md`, `docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md`, `scripts/check.sh`

---

## Итог (Summary)

**Вердикт: закрытие без возврата в Dev.** Полный гейт формально красный, но единственный
отказ — самозамыкающая нога (д) стаба `ac-128`: at-acceptance дополнение волны-2
`docs/60-implementation/acceptance/2026-11-21-render-quality-wave2-at-acceptance.md`
ещё не написано — этот прогон ему и предшествует (ат-design волны-2, «Что должен сделать
Dev», п. 5: документарное закрытие D4 зеленит `ac-128`). Весь кодовый и тестовый корпус
зелёный: 17 из 18 офлайн-стабов render-quality, живой прогон прибора 21/21 без
расхождений, все прочие сьюты `--full` зелёные, хвостовой `--fast` PASS. Классификация
единственного отказа: **плановая краснота закрытия (pending closure artifact)** —
не regression, не flaky, не env.

| Показатель | Значение | Лог |
|---|---|---|
| Отказов в прогоне | 1 (стаб `ac-128`, нога д) | 672–673, 679–680 |
| Офлайн-стабы render-quality | 17 PASS / 1 FAIL | 675–677 |
| Живой прогон прибора | `fixtures=21 match=21 divergence=0`, `verdict: PASS` | 750–752 |
| Сьюты `--full` (прочие) | все зелёные (таблица ниже) | 297–651 |
| Валидация docs / render-linter / shellcheck | `Errors: 0, Warnings: 6` / `ERROR=0` / clean | 363, 368, 371 |
| Хвостовой `gate-gramax-fast.sh` | `RESULT: PASS` | 781–782 |
| Итог `check.sh --full` | `FAILED`, rc=1 — только из-за ac-128 (д) | 754–755, 784–785 |

---

## Классификация отказов (таксономия дома: regression / new / flaky / env)

### Единственный красный: `ac-128-docs-closure.sh`, нога (д)

| Атрибут | Значение |
|---|---|
| Файл:место | `tests/gramax/render-quality/ac-128-docs-closure.sh`; вывод — лог 672–673, перечень — 680 |
| Класс | **плановая краснота закрытия** (pending closure artifact); в терминах дома — не дефект ни кода, ни теста; плановая NEW-нога TDD-цикла, чей артефакт пишется на закрытии волны |
| Вероятная причина | файл `docs/60-implementation/acceptance/2026-11-21-render-quality-wave2-at-acceptance.md` не существует — он и есть закрываемый артефакт (FR-207а: судьба th, факты пробных страниц, заключения tier-1); путь зафиксирован at-design волны-2 |
| Действие | дополнение пишет BA-acceptance на закрытии волны; после посадки — повторный `--full`; возврат в Dev не требуется |

Доказательства класса (каждая строка проверена этой сессией):

| Проверка | Факт |
|---|---|
| Не flaky | проверка существования файла детерминирована: повтор стаба по имени в этой сессии — rc=1, тот же единственный ассерт (2 из 2 прогонов идентичны) |
| Не env | стаб офлайн: существует/не существует локальный файл, окружение и сеть не участвуют |
| Не regression | `git log --all` по пути дополнения — пуст (артефакт ни разу не существовал); стаб рождён красным в `0016e62` с тремя красными ногами, циклы `0b71ce2`→`b04ec63`→`f8af038` зеленели ноги (а)(б)(в) — красных стало меньше, ни один зелёный ассерт не сломался |
| Плановость | README сюиты (инвентарь волны-2): нога (д) — «пишется на закрытии волны (FR-207а)»; at-design волны-2: замер при посадке — `3 assertion(s) failed`, сейчас — `1` |

---

## Регрессионный анализ: нет регрессий

Сьюты, затронутые волной-2, зелёные в этом же прогоне:

| Объект | Результат | Лог |
|---|---|---|
| render-linter (перекалибровка th) | 21/21 PASS, включая адаптированные ноги: ac-001 (warn L10), ac-003/ac-004 (warn, «калибровка 2026-11-21»), ac-011 (severity=WARN), ac-012 (W034 молчит), ac-014 (allowlist/многострочная ERROR) | 624–650 |
| render-quality волна-2 (стабы) | ac-120, ac-121, ac-123, ac-126, ac-127 — PASS | 667–671 |
| render-quality волна-1 (стабы) | ac-104…ac-113, ac-117, ac-118 — PASS (12/12) | 655–666 |
| Живой прогон (настроенная цель) | 21/21 match, divergence=0; `th-in-table` — OK 2xx (200), expect ok → match (понижение подтверждено на живой цели); подтверждённые киллеры `note-inline`, `colgroup-multiline` — STABLE_5XX, expect kill → match; дрейф-фикстуры ok → match | 684–751 |
| pytest-ноги плагина | в логе `--full` отсутствуют: гейт исполняет bash-сюиты; единственные pytest-подобные счётчики — `PASS=24 FAIL=0` у nauta-инструментов `test-check-id.sh` и `test-validate-content.sh` | 297, 340 |

Все прочие сьюты `--full` (контекст регрессии):

| Сьюта | Результат | Лог |
|---|---|---|
| nauta-integration / plugin-contract | 8/8 / 7/7 | 389–411 |
| catalog-validator / mermaid-adoption | 36/36 / 10/10 | 454–479 |
| writer-consumer-rules / link-form-resolver / link-form-migration | 11/11 / 8/8 / 7/7 | 495–535 |
| export-skill / plantuml-bpmn / writer-sync-470 / writer-tail-480 | 10/10 / 12/12 / 24/24 / зелёная | 550–620 |
| render-linter | 21/21 | 646–651 |
| Валидация docs / render-линтер / shellcheck / orphan-references / submodules | `Errors: 0, Warnings: 6` / `файлов=118, ERROR=0` / clean / clean / sync | 363–376 |

---

## Неназванное в брифе (зафиксировать в записи)

| Наблюдение | Лог | Оценка |
|---|---|---|
| `measure-session-cost.py`: NOT-MEASURED, код 3 soft (транскрипт сессии не найден) | 232–235 | штатное состояние прогона (ADR-102 Д5), не отказ; в дерево не пишется |
| `check-content-actuality.py`: 92 «неопределим», 13 актуален, 0 устарел, код 1 soft; среди SIGNAL — сама запись замера волны-2 `2026-11-21-render-calibration-th.md` и `2026-11-21-render-calibration-validate-render.md` | 129–130, 148 | soft-класс, не блокирует; причина SIGNAL у записи замера — маркер `**Опоры:**` стоит в конце файла, а не в шапке, резолвер его не видит. Автору дополнения at-acceptance: маркер — сразу после H1 (форма sibling-отчётов); ремонт формы — владельцу записи/PM, qa-runner документацию не правит |
| STABLE_5XX-ноты «кандидат на переиндексацию; окно gram.ax не установлено (RES-009 §6, NFR-080)» у `colgroup-multiline` и `note-inline` | 691, 730 | именованная нота прибора, expect kill → match — не отказ |
| Fail-soft агрегация: после `FAIL: render-quality suite` шаги продолжились, хвостовой `gate-gramax-fast.sh` исполнен и PASS | 753–782 | декомпозиция `RESULT: FAIL` выполнена: скрытых красных шагов нет |
| shellcheck clean на полном скане `git ls-files '*.sh'` | 371 | после вчерашних фиксов SC2034/SC2059 (отчёт 2026-11-21-playwright) корпус чист |
| TPL-69 Warnings: 6 | 18–23, 363 | все шесть — до-волновые файлы (ADR-0020 + 5 requirements), известный мягкий долг |

---

## Проваленные тесты (детали)

| Тест | Класс | Вероятная причина | Действие |
|---|---|---|---|
| `tests/gramax/render-quality/ac-128-docs-closure.sh` (нога д) | плановая краснота закрытия (не regression/flaky/env) | отсутствует закрываемый артефакт `docs/60-implementation/acceptance/2026-11-21-render-quality-wave2-at-acceptance.md` (повтор стаба rc=1; `git log --all` по пути пуст) | артефакт пишет BA-acceptance (FR-207а; путь at-design D4 п. 5), затем повторный `check.sh --full` |

---

## Рекомендация

- [ ] merge
- [x] block (формально: гейт красный до посадки артефакта закрытия) — **не** «block + back to Dev»: кодовых и тестовых работ не осталось
- [ ] re-run (flaky)

**Rationale:** единственный отказ — самозамыкающая нога закрытия волны: дополнение
at-acceptance, которое этот прогон и предшествует. Кодовая/тестовая приёмка волны-2
зелёная полностью (17/18 стабов + live probe 21/21 + все сьюты `--full`). По красной
линии merge не объявляется: класс «плановая краснота закрытия» — не подтверждённые
flaky/env. Порядок: BA-acceptance пишет дополнение (заодно нивелируя SIGNAL формы
`render-calibration-th.md`), затем повторный `--full` — ожидаемо rc=0.
