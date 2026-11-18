---
title: "QA Report — навык export (экспорт DOCX/PDF: шаблоны, placement, CI/CD, статический портал)"
order: 12
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# QA Report — навык export (экспорт DOCX/PDF: шаблоны, placement, CI/CD, статический портал)

**Дата прогона:** 2026-11-18
**Ветка/дерево:** `main`, HEAD `99201c0`; на момент прогоновой серии дерево чистое (`git status --porcelain` — только незатреканный `.zcode/`, среда агента). Во время сессии параллельные потоки продолжали писать в общее дерево (validators-поток: fixtures и новые stub'ы `catalog-validator`; plantuml-поток: `plugins/gramax/skills/plantuml/`, правки `drawio`/`mermaid` SKILL.md) — на пять suite этого прогона это не влияет (финальное состояние — в «Постпроверке»), контрольный повторный прогон выполнен уже на этом состоянии
**Окно export-потока:** `9355b69^…1409740` — база stub'ов `9355b69` (красная фаза 0/10: `plugins/gramax/skills/export/` ещё не существует, проверено `git ls-tree`) → реализация Dev `1409740` (навык + suite). Контекстные коммиты параллельных потоков того же окна: `0b92ea6` (SA/BA wave2), `99201c0` (plantuml-bpmn красная фаза — **другой** поток)
**Tester:** QA-runner — независимый прогон; все цифры этого отчёта — собственное исполнение, не пересказ отчёта Dev
**Требование:** [Навык export — экспорт DOCX/PDF](../../30-requirements/2026-11-18-export-skill-requirement.md) (AC-041…AC-050)
**ADR:** [0022-export-skill-placement.md](../../00-project/adr/0022-export-skill-placement.md)
**Дизайн:** [2026-11-18-export-skill-design.md](../../40-architecture/2026-11-18-export-skill-design.md)
**Suite приёмки:** `tests/gramax/export-skill/` (README — карта AC → stub → уровень; ADR-0011 — таксономия)
**Опоры:** `tests/gramax/export-skill/README.md`, `docs/30-requirements/2026-11-18-export-skill-requirement.md`, `docs/40-architecture/2026-11-18-export-skill-design.md`, `docs/00-project/adr/0022-export-skill-placement.md`

---

## Summary

| Suite/проверка | Команда | Passed | Failed | Skipped | Exit |
|---|---|---|---|---|---|
| `export-skill` (приёмка AC-041…050) | `bash tests/gramax/export-skill/run.sh` | 10 | 0 | 0 | `0` |
| `plugin-contract` (regression) | `bash tests/gramax/plugin-contract/run.sh` | 7 | 0 | 0 | `0` |
| `writer-consumer-rules` (regression) | `bash tests/gramax/writer-consumer-rules/run.sh` | 11 | 0 | 0 | `0` |
| `cross-catalog-retraction` (regression) | `bash tests/gramax/cross-catalog-retraction/run.sh` | 9 | 0 | 0 | `0` |
| `link-form-migration` (regression) | `bash tests/gramax/link-form-migration/run.sh` | 7 | 0 | 0 | `0` |
| **Итого (AC-скрипты)** | | **44** | **0** | **0** | — |
| Композит `check.sh --fast` (AC-050) | `bash scripts/check.sh --fast` | — | — | — | `0` |

- **passed:** 44 (10 приёмка + 34 регрессия по четырём соседним suite)
- **failed:** 0
- **skipped:** 0
- **total:** 44
- **duration:** пять suite ≈ 15 c суммарно (`export-skill` 4 c — внутри него `ac-050` сам гоняет `check.sh --fast`; `cross-catalog-retraction` 8 c — два внутренних прогона `--fast` в `ac-001`/`ac-009`; остальные по 1 c); `check.sh --fast` отдельно ≈ 4 c
- **Итог одной строкой:** приёмочный suite export-потока зелёный при независимом прогоне (10/10), все девять буквальных grep-команд AC-041…AC-049 из требования исполнены дословно и дали OK, композит AC-050 — `exit=0` при `Errors: 0`; регрессия по четырём соседним suite не найдена (34/34, счёты без изменений, сами suite окном волны не тронуты). Рекомендация — **accept**.
- **Примечание к цифрам:** счёт 44/44 — приёмочный прогон, сделанный ДО записи этого отчёта (авторитетный для вердиктов AC). ПОСЛЕ записи отчёта детерминированно краснеют только три шага, исполняющие `check.sh --fast` внутри suite (`export-skill/ac-050`, `cross-catalog-retraction/ac-001в+ac-009`) — на собственной C1-ошибке этого отчёта; классификация (env), матрица повторного прогона и условие снятия — в разделе «Повторный прогон». Контентные AC-041…049 зелёные во всех прогонах сессии.

---

## Прогон suite → команда → код возврата (честный `$?`, не grep)

| # | Проверка | Команда | Код возврата | Время |
|---|---|---|---|---|
| 1 | Приёмка export (AC-041…050) | `bash tests/gramax/export-skill/run.sh` | `rc=0` (`All 10 AC tests passed.`) | 4 c |
| 2 | plugin-contract | `bash tests/gramax/plugin-contract/run.sh` | `rc=0` (7/7) | 1 c |
| 3 | writer-consumer-rules | `bash tests/gramax/writer-consumer-rules/run.sh` | `rc=0` (11/11) | 1 c |
| 4 | cross-catalog-retraction | `bash tests/gramax/cross-catalog-retraction/run.sh` | `rc=0` (9/9) | 8 c |
| 5 | link-form-migration | `bash tests/gramax/link-form-migration/run.sh` | `rc=0` (7/7) | 1 c |
| 6 | Fast-гейт (AC-050, буквально) | `bash scripts/check.sh --fast` | `rc=0`, `RESULT: PASS` | 4 c |

Полный вывод `check.sh --fast` прочитан целиком: `json` → OK, `content` → `Errors: 0 | Warnings: 6`, `render` → `файлов=87, ERROR=0`, `RESULT: PASS`. Ни одного отказавшего шага.

---

## AC coverage (AC-041…AC-050, сверка с картой README suite)

Каждый AC закрыт ровно одним stub'ом (`ac-0NN-<тема>.sh`), уровень по README: AC-041…AC-049 — integration (проверки артефактов), AC-050 — e2e (композит). Пропусков нет: все 10 stub'ов исполняемы и исполнены.

| AC | Stub | Результат suite | Буквальная команда из требования | Независимый результат |
|---|---|---|---|---|
| AC-041 | `ac-041-skill-surface-and-triggers.sh` | PASS | `test -f $S && grep -q '^name: export' … && echo OK` | `OK` |
| AC-042 | `ac-042-pdf-template-facts.sh` | PASS | grep `.page`, `title-page`, `колонтитул\|header\|footer` | `OK` |
| AC-043 | `ac-043-docx-template-facts.sh` | PASS | grep `dotx`, `word` | `OK` |
| AC-044 | `ac-044-portal-template-placement.sh` | PASS | grep `assets/pdf`, `assets/word` | `OK` |
| AC-045 | `ac-045-cli-export-recipe.sh` | PASS | grep `gramax-cli export` + `-f docx\|pdf` | `OK` |
| AC-046 | `ac-046-ci-stage-recipe.sh` | PASS | grep `gitlab-ci`, `EXPORT_FILE_PATH` | `OK` |
| AC-047 | `ac-047-static-portal-recipe.sh` | PASS | grep `статическ\|static` + `gramax-cli` | `OK` |
| AC-048 | `ac-048-ui-export-scope.sh` | PASS | grep `приложени`, `раздел`, `каталог` | `OK` |
| AC-049 | `ac-049-execution-boundary.sh` | PASS | grep `node` + альтернация `не исполняет\|…\|границ` | `OK` |
| AC-050 | `ac-050-composite-gate.sh` | PASS (приёмочный прогон) | `bash scripts/check.sh --fast; echo "exit=$?"` | `exit=0`, `Errors: 0`; после записи отчёта stub краснеет на собственной C1 отчёта — см. «Повторный прогон» |

Сверх формулы требования stub AC-041 дополнительно несёт хуки дизайна (шесть слов FR-131 в `description`, негативная демаркация export/writer, кросс-ссылка ровно одной строкой, структурный кейс FR-132) — всё зелёное. AC-050: предупреждение C10-orphan на новый файл допустимо формулой AC; фактически предупреждений-сирот на файлы потока нет (все 6 warnings — TPL-69 в старых файлах, см. регрессионный анализ), `Errors = 0` — условие выполнено.

**Границы покрытия (осознанно не автоматизировано, по README/design):** NFR-056/BR-007 (факт-гигиена, запрет изобретений) — процессная ревью-проверка по источникам, грепом не выражается; семантика роутинга триггеров — ревью.

---

## Регрессионный анализ

### Четыре соседних suite — счёт не изменился, сами suite волной не тронуты

`plugin-contract` 7, `writer-consumer-rules` 11, `cross-catalog-retraction` 9, `link-form-migration` 7 — все зелёные, счёты совпадают с предыдущими отчётами (`2026-08-13-link-form-contract-qa-report.md`: plugin-contract 7/7, writer-consumer-rules 11/11, link-form-migration 7/7; `2026-08-13-cross-catalog-retraction-qa-report.md`: 9/9). Дополнительно: `git diff --name-only 9355b69^..HEAD -- <четыре suite-каталога>` — **пусто** (в окно волны не входит ни один их файл; то же верно для `link-form-resolver`). Зелёный прогон неизменённого suite — отсутствие регрессии по построению, а не по совпадению счётов.

### export-skill — красная→зелёная цепочка, все 10 AC «new, first green»

На базе stub'ов `9355b69` каталога `plugins/gramax/skills/export/` не существует (`git ls-tree 9355b69 plugins/gramax/skills/` — пять навыков, export отсутствует) — suite красный 0/10 по дизайну, каждый stub падает на гейте существования. Реализация `1409740` создала навык (`SKILL.md` 162 строки + `references/templates.md` + `references/recipes.md`) — suite 10/10. Столбца «было зелёным до волны» у этих AC нет и быть не может — регрессом они быть не способны.

### Правка `writer/SKILL.md` — ровно по плану дизайна

`git show 1409740 -- plugins/gramax/skills/writer/SKILL.md` → `1 file changed, 1 insertion(+)`: одна строка `- \`gramax:export\` — экспорт DOCX/PDF, шаблоны экспорта, CI/CD, статический портал (guidance)`. Ничего сверх одной строки кросс-ссылки (план файлов дизайна); `writer-consumer-rules` 11/11 и `ac-041` (демаркация description'ов) зелёные — соседний навык не задет.

### Fast-гейт: 6 warnings — все досинтетические, в файлах вне окна волны

`Errors: 0 | Warnings: 6` — все шесть TPL-69 («склеенный абзац») в `docs/00-project/adr/0020-…` и пяти `docs/30-requirements/2026-05-*`/`2026-08-*` файлах; последние касания этих файлов — коммиты `90fb994`/`ad7f1a4`, в окно `9355b69^…HEAD` они не входят (`git diff --name-only` окна их не содержит). Ни один warning не указывает на файл export-потока. Контекст дерева, не находка этого прогона.

**Вывод:** регрессий не найдено ни в одном из проверенных пластов (приёмка, 4 соседних suite, fast-гейт, правка writer). Три отказа контрольного прогона после записи отчёта — не регрессия: их класс env с доказательствами вынесен в отдельный раздел «Повторный прогон».

---

## Failed tests (детали)

**Приёмочный прогон (авторитетный для вердиктов AC-041…050, до записи отчёта):** ни один AC-скрипт не упал ни в одном из пяти suite и в fast-гейте. Таблица пуста намеренно, не пропущена молча:

| Test | Reason category | Probable cause | Action |
|---|---|---|---|
| — (отказов нет) | — | — | — |

**Повторный прогон ПОСЛЕ записи отчёта:** три отказа, все одного класса — см. «Повторный прогон» ниже:

| Test | Reason category | Probable cause | Action |
|---|---|---|---|
| `export-skill/ac-050-composite-gate.sh` | **env** | внутренний `check.sh --fast` видит единственный error — C1 на файл ЭТОГО отчёта (не зарегистрирован в `_index.md`; изоляция роли запрещает QA-runner править `_index.md`) | PM: регистрация строки отчёта в `docs/60-implementation/test-reports/_index.md` |
| `cross-catalog-retraction/ac-001 (часть в)` | **env** | тот же гейт, та же единственная C1 | тот же |
| `cross-catalog-retraction/ac-009` | **env** | тот же гейт, та же единственная C1 | тот же |

---

## Контекст прогона (не находки отказов)

- **`plantuml-bpmn` — красная фаза 0/12 другого потока.** Suite присутствует в дереве (коммит `99201c0`, failing-stub'ы AC-051…062), в бриф этого прогона не входит и мной не запускался; в `scripts/check-gramax.sh` не зарегистрирован — на гейты не влияет. Красная фаза — проектное состояние TDD-цепочки соседнего потока, не дефект export-потока.

- **`cross-catalog-retraction` `ac-002` печатает MANUAL-заметку** (часть «в» — семантическая проверка снятия противоречия, честно не автоматизируемая по ADR-0017, ручной шаг перед финальным sign-off). Существующая задокументированная граница автоматизации соседнего suite, тест при этом PASS — не отказ.

- **Инструментальная заметка:** запуск pytest по `.sh`-suite'ам не собирает ни одного теста — в сборке этого дерева pytest отвечает `ERROR: not found … (no match in any of [<Dir …>])`, rc=4 (бриф называл форму rc=5 «no tests ran»; суть одна — коллекция по bash-файлам пуста). Авторитетный раннер bash-suite'ов — `run.sh` по ADR-0011; известная особенность прибора, дефектом не считается.

#### `export-skill` НЕ зарегистрирован в `check-gramax.sh --full` — действие для PM

Зарегистрированы 9 suite: orphan-references, nauta-integration, plugin-contract, catalog-validator, mermaid-adoption, writer-consumer-rules, link-form-resolver, link-form-migration, render-linter; `export-skill` и `plantuml-bpmn` среди них нет. По README suite это сознательная изоляция параллельных потоков: регистрацию делает **PM централизованным пакетом** (блок по образцу render-linter + строка в шапке). До регистрации авторитетный прогон приёмки — standalone `run.sh` (этот отчёт). Действие для PM: включить suite в пакет регистрации, иначе AC-041…049 выпадут из `--full`-гейта.

#### Собственная C1-ошибка этого отчёта — ожидаемая

После записи отчёта fast-гейт красный ровно на одном error: C1 (файл не зарегистрирован в `_index.md` раздела) + C10-warning на тот же файл; оба снимаются PM-регистрацией строки в `docs/60-implementation/test-reports/_index.md` (изоляция роли: QA-runner `_index.md` не правит). Подробное разведение с вердиктом AC-050 — в «Постпроверке».

---

## Повторный прогон после записи отчёта (классификация отказа)

Сессия — не одиночный момент: пять suite прогнаны дважды (приёмочный прогон до записи отчёта и контрольный после), fast-гейт — шесть раз (приёмка №6 таблицы выше + пять постпроверок после записи/правок отчёта; итоговое состояние стабильно: `Errors: 1 | Warnings: 7`, единственный error — собственная C1). Матрица:

| Suite | Приёмочный прогон (до записи отчёта) | Повторный прогон (после записи) | Дельта |
|---|---|---|---|
| `export-skill` | 10/10, `rc=0` | 9/10, `rc=1` — FAIL `ac-050` | только шаг с внутренним `check.sh --fast` |
| `cross-catalog-retraction` | 9/9, `rc=0` | 7/9, `rc=1` — FAIL `ac-001` (часть в), `ac-009` | только шаги с внутренним `check.sh --fast` |
| `plugin-contract` | 7/7, `rc=0` | 7/7, `rc=0` | нет |
| `writer-consumer-rules` | 11/11, `rc=0` | 11/11, `rc=0` | нет |
| `link-form-migration` | 7/7, `rc=0` | 7/7, `rc=0` | нет |

Контентные AC export-потока (AC-041…AC-049) зелёные во всех прогонах сессии — предмет стабилен.

**Классификация трёх повторных отказов: `env`** (состояние дерева/среды гейта, не код предмета), с доказательством по каждому правилу таксономии:

- **Не regression:** приёмочные AC зелёные во всех прогонах; краснеют исключительно ассерты вида «`check.sh --fast` обязан завершаться кодом 0», и единственный error гейта в момент отказа — C1 на файл этого отчёта (хвост вывода гейта — в «Постпроверке»). Код навыка и suite между прогонами не менялся.
- **Не new (продукта):** отказ создан не Dev-кодом, а артефактом самой QA-сессии — файлом отчёта, который бриф прямо разрешает оставить незарегистрированным («No _index.md — PM wires; one own-file C1 registration error is expected»).
- **Не flaky:** детерминировано — 2 повтора из 2 с идентичным отказом; причина воспроизводится точечно (grep лога гейта даёт ровно один `[error]`).
- **Условие снятия:** PM-регистрация отчёта в `_index.md` возвращает гейт в `Errors: 0` — все три отказа исчезают без единой правки кода/тестов.

**Урок параллельной работы (для PM, сюда помещён вместо lessons-learned — изоляция роли):** запись QA-отчёта в дерево с гейт-зависимыми suite (`ac-050`, `cross-catalog` `ac-001в`/`ac-009`) переворачивает чужие suite до момента PM-регистрации; следующему qa-runner в параллельной сессии стоит читать дату/состояние дерева, прежде чем классифицировать чужой красный `check-fast`-шаг как отказ потока.

---

## Рекомендация

- [x] **accept** — передача в BA-acceptance / `pm-review`
- [ ] fix-first (block + назад в Dev)
- [ ] re-run (flaky)

**Обоснование:** приёмочный suite зелёный при независимом прогоне (10/10), каждый AC-041…AC-050 прослеживается до PASS своего stub'а, а девять контентных AC дополнительно подтверждены дословным исполнением команд из требования; AC-050 — `exit=0`, `Errors: 0` (приёмочное дерево). Регрессия исключена конструктивно: все четыре соседних suite не изменены окном волны и зелёные (34/34), контентные AC стабильно зелёные во всех прогонах сессии. Три отказа повторного прогона классифицированы **env** с доказательствами (см. «Повторный прогон»): причина — собственная C1-ошибка этого отчёта в общем гейте, не код потока; блокером merge они не являются по красной линии «не принимать merge, пока отказ не получил подтверждённый env-класс с зафиксированным способом снятия» — класс подтверждён, способ снятия (PM-регистрация в `_index.md`) назван. Действия вне Dev: (1) PM-регистрация строки этого отчёта в `_index.md`, (2) PM-пакет регистрации suite в `check-gramax.sh --full`, (3) ревью-проверки, грепом не выражаемые (NFR-056/BR-007 — по README/design).

**Передача:** BA-acceptance gate → Tech-writer (release-flow: bump до следующей версии делает Tech-writer, номер не зарезервирован — README suite, «Границы покрытия»). Код/тесты/контент этой QA-сессией не менялись (красная линия роли) — единственный новый файл: этот отчёт; строку в `_index.md` добавляет PM — до этого fast-гейт несёт ровно одну ожидаемую own-file C1-ошибку и C10-warning на этот отчёт (см. «Контекст прогона» и «Постпроверку»).

---

## Постпроверка

После записи этого отчёта:

```
$ bash scripts/check.sh --fast; echo "GATE_RC=$?"
GATE_RC=1     # Errors: 1 | Warnings: 7 — ЕДИНСТВЕННЫЙ error: C1-регистрация на сам этот отчёт:
# «docs/60-implementation/test-reports/2026-11-18-export-skill-qa-report.md: не зарегистрирована
# ссылкой в docs/60-implementation/test-reports/_index.md … [error]»; +1 warning C10-orphan на тот же файл.
# Бриф задачи прямо ожидает этот own-file C1 («No _index.md — PM wires; one own-file C1 registration
# error is expected»): регистрацию строки в _index.md делает PM, QA-runner её не правит.
$ git status --porcelain   # финальное состояние сессии — параллельные потоки писали одновременно
?? .zcode/            # среда агента, была до прогона
?? docs/60-implementation/test-reports/2026-11-18-export-skill-qa-report.md   # единственный файл ЭТОЙ сессии
?? plugins/gramax/skills/plantuml/                                            # параллельный plantuml-поток
 M plugins/gramax/skills/drawio/SKILL.md                                      # параллельный поток
 M plugins/gramax/skills/mermaid/SKILL.md                                     # параллельный поток
?? tests/gramax/catalog-validator/… (fixtures/validators-parity/, ac-025…028) # validators-поток
```

**Разведение вердиктов (честно, без смешения):** AC-050 измерен ДО записи отчёта — на дереве без файлов этой сессии он давал `exit=0`, `Errors: 0` (см. прогон №6). Краснота fast-гейта ПОСЛЕ записи вызвана ровно одной собственной C1-ошибкой отчёта (ожидаемой брифом) и одним C10-warning на тот же файл; к export-потоку (навык, suite, требования, соседние suite) она отношения не имеет. После PM-регистрации отчёта в `_index.md` гейт возвращается в зелёный без каких-либо правок содержания.

Правки кода продукта, тестов, навыков и `content/`-контента этой сессией не вносились.
