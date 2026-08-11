---
title: "QA Report — наведение порядка в test harness gramax и doc-paths (gramax 4.1.1)"
order: 5
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# QA Report — наведение порядка в test harness gramax и doc-paths (gramax 4.1.1)

**Date:** 2026-08-10
**Branch:** `feat-harness-taxonomy`
**HEAD:** `412211d`
**Tester:** QA-runner
**Требование:** [content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md](../../30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md)
**ADR:** `content/00-project/adr/0011-test-harness-taxonomy.md`

---

## Summary

- **passed (живые suite):** 19 AC-тестов (`orphan-references` — 1 агрегированная проверка, `nauta-integration` — 8, `plugin-contract` — 7, `doc-paths` — 2, суммарно = 18 именованных AC-тестов + 1 orphan-references) — все зелёные
- **failed:** 0
- **skipped:** 0
- **AC требования (2026-08-09), проверено механически:** 35 из 35 (AC-001…AC-035) — все PASS
- **duration:** `bash scripts/check.sh --full` — ≈ 7 c (real 6.72s); `--fast` — < 2 c
- **run command (композит):** `bash scripts/check.sh --full`; результат читан целиком, без `grep`/`tail`, по коду возврата и последней непрефильтрованной строке `RESULT:` (см. «Regression analysis» — это прямой урок цикла)

**Итог одной строкой:** полный пак живых suite зелёный, `--full` завершается с `exit=0`, все 35 механически проверяемых AC требования выполнены, архив зафиксирован как не исполняемый нигде. Рекомендация — **merge**.

---

## Прогон suite → счёт → вердикт

| Suite | Подключён к `--full`? | Счёт | Вердикт |
|---|---|---|---|
| `tests/gramax/orphan-references/run.sh` | да | PASS (1 агрегированная проверка) | зелёный |
| `tests/gramax/nauta-integration/run.sh` | да | 8/8 PASS | зелёный |
| `tests/gramax/plugin-contract/run.sh` | да | 7/7 PASS | зелёный |
| `tests/gramax/doc-paths/run.sh` | да | 2/2 PASS | зелёный |
| `tests/gramax/archive/remove-diagram-skills/` | **нет** | не считается (BR-001/NFR-004) | заморожен, не входит в счёт |
| `tests/gramax/archive/routing-mermaid-drawio/` | **нет** | не считается (BR-001/NFR-004) | заморожен, не входит в счёт |
| `tests/gramax/archive/mermaid-file-based/` | **нет** | не считается (BR-001/NFR-004) | заморожен; `verify.sh` — ручной, вне счёта |
| `tests/gramax/diagram-on-demand/` | — | удалён (`git rm -r`) | не существует, ожидаемо |
| `bash scripts/check.sh --fast` | — | PASS | зелёный |
| `bash scripts/check.sh --full` | — | PASS, `exit=0` | зелёный (прочитан полностью, без фильтрации) |

Каждый живой suite прогнан и как часть `--full`, и отдельным прямым вызовом (`bash tests/gramax/<suite>/run.sh`) — результаты идентичны в обоих режимах.

---

## Regression analysis

**Состояние до цикла (перепроверено независимо).** Задание указывало, что `--full` был красным на стартовом коммите `c9be893` (падал шаг `shellcheck`). Не принял это на веру — поднял отдельный `git worktree --detach c9be893` и прогнал там `bash scripts/check.sh --full` целиком, без фильтрации:

```
==> shellcheck
… (94 замечания на живых .sh и на tests/gramax/diagram-on-demand/…)
FAIL: shellcheck issues
==> submodule status
OK: submodules in sync
==> orphan-references
OK: orphan-references clean
==> nauta-integration
… All 8 AC tests passed.
OK: nauta-integration AC suite green
==> RESULT: FAIL
EXIT=1
```

Подтверждено: на `c9be893` шаг `shellcheck` красный, оба подключённых на тот момент suite (`orphan-references`, `nauta-integration`) — зелёные. Это исходная точка цикла, не результат текущей работы. Worktree удалён после проверки (`git worktree remove --force`).

**Что изменилось к HEAD `412211d`.** По `git log c9be893..HEAD` — 30 коммитов. Ключевые для регрессионного анализа:

| Коммит | Что сделал |
|---|---|
| `62b62f2` | `git mv` трёх suite в `archive/`, `git rm -r diagram-on-demand/`, `archive/README.md` |
| `a9cffef` | новый suite `tests/gramax/plugin-contract/` |
| `3339ffe` | продуктовый фикс: миграция drawio-тега + WARNING по ADR-0008 в `writer/SKILL.md` и `README.md` |
| `e695a46` | расширение `sunset-registry.txt` (`claude-mermaid`, `diagram-on-demand`, `diagrams`) |
| `22e6c77` | новый suite `tests/gramax/doc-paths/` |
| `e1afaf6` | починка 41 нерабочего `docs/`-указателя в `content/` |
| `155e565`, `e8c7239`, `2a1d10e`, `6261415`, `d8013b5` | фиксы гейтов по находкам собственного тестирования (freshness allowlist, subshell FAIL, prefix-matching) |
| `3786af3` | шаг `shellcheck` в `--full` осмысленный и зелёный (флаги `-x -P SCRIPTDIR`, исключение архива) |

**Регрессий на живом коде нет.** Все suite, зелёные до цикла (`orphan-references`, `nauta-integration`), остаются зелёными после. Красных живых suite на HEAD не найдено — соответственно классифицировать по regression/new/flaky/env нечего: **упавших тестов в текущем прогоне 0**.

**Тесты, которые были красными и стали неактуальными не через фикс, а через архивацию** (`remove-diagram-skills`, `routing-mermaid-drawio`, `mermaid-file-based`) — не «исправлены», а выведены из эксплуатации `git mv` в `archive/` согласно ADR-0011 Решение 1 и не считаются ни в одном отчёте (см. ниже). Их прежний красный счёт (11/16, 14/18, 2/13 — по требованию, раздел «Что обнаружено») зафиксирован там же как исторический факт и не пересчитывался.

---

## Архив — проверено, что не исполняется

`tests/gramax/archive/**` содержит собственные `run.sh`/`run-all.sh` (например `archive/remove-diagram-skills/run.sh`, `archive/routing-mermaid-drawio/run-all.sh`) — но ни один агрегатор их не вызывает:

```
$ grep -rn "archive" scripts/check.sh tests/gramax/*/run.sh
tests/gramax/orphan-references/run.sh:30: EXCLUDE_RE='…|^tests/gramax/archive/'
scripts/check.sh:74-82: … tests/gramax/archive/ … | grep -v '^tests/gramax/archive/' …
```

Оба совпадения — **исключения** (архив вычитается из скана shellcheck и из скана остаточных ссылок), не вызовы. Прямая проверка на инвариант AC-005 (`! grep -qE 'bash +tests/gramax/archive' scripts/check.sh`) — PASS.

Единственное исполняемое исключение внутри архива — `tests/gramax/archive/mermaid-file-based/verify.sh` (параметризованный ручной верификатор, не `ac-*.sh` и не входит в `run.sh` самого архивного suite). Прогнан в двух режимах, требуемых заданием:

| Режим | Ожидание | Факт |
|---|---|---|
| без аргумента | usage на stdout/stderr, `exit=2` | `usage: verify.sh <output-dir>` + пояснение по структуре каталога, `EXIT=2` — совпало |
| на пустом каталоге (`mkdir` без содержимого) | несколько `FAIL`, `exit=1` | `FAIL: AC-001 …mermaid-файл не создан`, `FAIL: AC-003 …статья не найдена`, `FAILED: 2 проверок не прошли`, `EXIT=1` — совпало |

Полноценный (позитивный) прогон `verify.sh` требует живого вызова `gramax:mermaid` на тестовой статье — этого я **не выполнял** (вне мандата QA-runner, требует реального обращения к скиллу, не bash-harness). См. «Не покрыто автоматикой».

Читателю прежних отчётов: suite `remove-diagram-skills`, `routing-mermaid-drawio`, `mermaid-file-based` **не пропали** — они переехали `git mv` (история видна через `git log --follow`) в `tests/gramax/archive/<suite>/` и заморожены байт-в-байт (кроме нового `verify.sh`). Проверил это не только чтением `archive/README.md`, но и независимо, командой сверки с коммитом-родителем переезда:

```
BASE_REV="62b62f2^"
# для каждого файла трёх suite:
diff <(git show "$BASE_REV:tests/gramax/<suite>/<file>") tests/gramax/archive/<suite>/<file>
```

Результат: **62 файла, 0 расхождений** — побайтовое совпадение подтверждено (AC-003 PASS). `diagram-on-demand/` удалён целиком (`git rm -r`, не архивирован) — обоснование в `content/60-implementation/acceptance/2026-05-08-diagram-on-demand-acceptance.md`; факт приёмки уже зафиксирован там же, повторно не архивируется.

---

## AC coverage (content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md)

Все 35 AC требования сформулированы как исполняемые bash-однострочники — каждый прогнан дословно.

### Таксономия

| AC | Проверка | Результат |
|---|---|---|
| AC-001 | директории `plugin-contract`, `doc-paths`, `archive` существуют | PASS |
| AC-002 | `archive/README.md` фиксирует ретировку поля `skills` | PASS |
| AC-003 | побайтовое совпадение архива с коммитом до `git mv` (62 файла) | PASS |
| AC-004 | `diagram-on-demand/` удалён | PASS |
| AC-005 | `check.sh` не *вызывает* архив (только упоминает как исключение) | PASS |
| AC-006 | `verify.sh` существует, без аргумента печатает usage с `output-dir` | PASS |

### plugin-contract

| AC | Проверка | Результат |
|---|---|---|
| AC-007 | роутинг drawio ↔ mermaid (уже зелёный до фиксов — regression guard) | PASS |
| AC-008 | канонический `<drawio path=… width=… height=…/>` в `writer/references/drawio.md` | PASS |
| AC-009 | нигде в живых доках нет `[drawio:`/`<Image src`, кроме помеченного `blocks.md` | PASS |
| AC-010 | структура `writer/references/drawio.md` (Prerequisites и т.д.) | PASS |
| AC-011 | `README.md` — prerequisites + WARNING по ADR-0008 Решение 6 | PASS |
| AC-012 | контракт `mermaid/SKILL.md` (naming, `_index.md`, `800px`/`450px`, без устаревшей фразы) | PASS |
| AC-013 | `plugin.json.version == marketplace.json.metadata.version` | PASS |
| AC-014 | `CHANGELOG.md` содержит секцию текущей версии | PASS |
| AC-015 | `plugin-contract/` не содержит ассерта на поле `skills` | PASS |
| AC-016 | `sunset-registry.txt` расширен, `orphan-references` зелёный целиком (без ложных срабатываний) | PASS |
| AC-017 | `EXCLUDE_RE` — принцип `^tests/gramax/archive/`, не список имён | PASS |
| AC-018 | `plugin-contract`/`doc-paths` упомянуты в `check.sh` | PASS |

### Продуктовые фиксы v4.1.1

| AC | Проверка | Результат |
|---|---|---|
| AC-019 | `writer/SKILL.md` — без устаревшего синтаксиса, с каноническим тегом | PASS |
| AC-020 | `README.md` — без устаревшего синтаксиса, с каноническим тегом | PASS |
| AC-021 | `check.sh` не упоминает `claude-mermaid` | PASS |
| AC-022 | `CHANGELOG.md` — секция `## 4.1.1` с `### Fixed` | PASS |
| AC-023 | `plugin.json` версии `4.1.1` | PASS |
| AC-024 | `marketplace.json` — изменилось только поле `version`, остальные поля целы | PASS |

### doc-paths

| AC | Проверка | Результат |
|---|---|---|
| AC-025 | точечные указатели заменены на новые пути, гейт зелёный | PASS |
| AC-026 | `allowlist.txt` — ровно 14 точечных записей `file:line — причина` | PASS |
| AC-027 | гейт зелёный на чистом дереве | PASS |
| AC-028 | фикстура рассинхрона allowlist существует | PASS |
| AC-029 | два спека вне периметра (`apply-project-template-design`, `nauta-integration-design`) не задеты | PASS |

### Онбординг

| AC | Проверка | Результат |
|---|---|---|
| AC-030 | `docs/onboarding-nauta.md` содержит `v0.3.1`, `settings.local.json`, `uv`, `install-hooks.sh` | PASS |
| AC-031 | `.claude/settings.local.json.example` закоммичен | PASS |
| AC-032 | `CLAUDE.md` ссылается на онбординг | PASS |
| AC-033 | `README.md` ссылается на онбординг | PASS |

### Композитный AC

| AC | Проверка | Результат |
|---|---|---|
| AC-034 | `bash scripts/check.sh --full` завершается `exit=0` | PASS |
| AC-035 | шаг `shellcheck` — флаги `-x -P SCRIPTDIR` + исключение `tests/gramax/archive/` | PASS |

**Итог AC:** 35/35 PASS. Нет ни одного AC без теста и ни одного red — stub'ов от qa-author, оставшихся невыполненными, не найдено.

---

## Failed tests (детали)

Пусто — упавших тестов в прогоне на HEAD `412211d` нет. Ни один из 4 живых suite, ни `check.sh --fast`, ни `check.sh --full` не дали ни одного `FAIL`. Соответственно классификация regression/new/flaky/env не применяется — классифицировать нечего.

---

## Не покрыто автоматикой

1. **Живой (позитивный) прогон `tests/gramax/archive/mermaid-file-based/verify.sh`.** Проверен только контракт вызова (usage без аргумента, `FAIL`-набор на пустом каталоге) — обе ветки соответствуют ожиданию. Полноценная проверка (файл `.mermaid` реально создан, DSL валиден, тег вставлен с правильными атрибутами, имя соответствует конвенции на реальных данных) требует живого вызова скилла `gramax:mermaid` на тестовой статье и **не выполнялась** в этом прогоне — вне мандата QA-runner (bash-harness не может вызвать LLM/skill). Процедура, которой это делается вручную (описана в `tests/gramax/archive/README.md`):
   ```
   1. Создать тестовую статью в пустом каталоге: /tmp/mtest/docs/auth/overview.md
   2. Вызвать gramax:mermaid на ней (тема — «процесс авторизации», diagram-slug «auth-flow»)
   3. bash tests/gramax/archive/mermaid-file-based/verify.sh /tmp/mtest
   ```
   Это не блокирует merge: статическая половина того же контракта (naming, дефолтные атрибуты, запрет молчаливой перезаписи, устаревшая формулировка) уже покрыта `plugin-contract/ac-005-mermaid-file-based-contract.sh` и прошла (см. AC-012 выше).
2. **Живая проверка WARNING/routing-контракта в реальном диалоге с Claude.** `plugin-contract/ac-001`, `ac-004` проверяют текст `SKILL.md`/`README.md` статически (регексами), не фактическое поведение выбора skill'а в разговоре. Смоук с реальным неоднозначным запросом («нарисуй диаграмму») — вне мандата этого прогона.
3. **`content/`-валидатор (`uv run scripts/validate-content.py`) как таковой** — не тестируется на собственные баги в этом цикле (это чужой инструмент, доставленный из nauta, `scripts/*.py` — не трогаем по красной линии). Прогнан только как чёрный ящик внутри `check.sh --fast`/`--full`, оба раза зелёный.

---

## Известные ограничения

Разобраны финальным ревью цикла и признаны неблокирующими. Проверил присутствие каждого в коде — подтверждено:

| Ограничение | Где | Подтверждение |
|---|---|---|
| `plugin-contract/ac-002` исключает `references/blocks.md` **целиком**, а не только помеченный «устаревший формат» абзац | `tests/gramax/plugin-contract/ac-002-drawio-tag-format.sh:23` | `grep -v '/references/blocks\.md:'` — файловый, не построчный фильтр; единственный выживший мутант при мутационном прогоне (по формулировке требования) |
| `plugin-contract/ac-007` (сторож ретировки поля `skills`) обходится ассертом, написанным в другом стиле кавычек | `tests/gramax/plugin-contract/ac-007-retired-skills-field.sh:14` | паттерн `get\('skills'\)\|\[.skills.\]\|"skills"` — использует `\[.skills.\]` (точки как wildcard для кавычек), а не литеральный `\['skills'\]`, как в AC-015 формулировки требования; при другом стиле кавычек в гипотетическом «возвращённом» ассерте сторож может не сработать |
| `tests/gramax/doc-paths/lib/scan.sh` ломается на пути с двоеточием в имени файла — отказ в безопасную сторону (ложный FAIL) | `tests/gramax/doc-paths/lib/scan.sh:64-66` | разбор находки `grep -rnE` идёт через `file="${hit%%:*}"` / `cut -d: -f2` — предполагает ровно один структурный `:` (разделитель file:line); двоеточие внутри самого имени файла срезало бы путь неверно. В `content/` таких файлов сегодня нет, риск теоретический, отказ ложно-негативный (FAIL, не молчаливый PASS) |
| `nauta-integration/ac-004` использует `find` без гарантии алфавитного порядка — латентно, срабатывает только при коллизии номеров ADR | `tests/gramax/nauta-integration/ac-004*.sh:24,38` | `find "$ADR_DIR" -maxdepth 1 -name "${n}-*.md" \| head -1` — при двух ADR с одинаковым номером-префиксом результат зависит от порядка обхода файловой системы, не детерминирован. Сегодня коллизий номеров ADR нет (проверено — 11 ADR, номера 0001…0011, уникальны) |

Все четыре — известны, задокументированы заданием цикла как разобранные финальным ревью, не новые находки этого прогона. Ни одно не проявилось как фактический failed test в текущем состоянии репозитория.

---

## Рекомендация

- [x] merge
- [ ] block + назад в Dev
- [ ] re-run (flaky)

**Обоснование:** полный пак (4 живых suite + `check.sh --fast` + `check.sh --full`) зелёный на HEAD `412211d`, `--full` завершается `exit=0` при полном непрефильтрованном чтении вывода (не по гипотезе — перепроверено дважды: на HEAD и, для контраста, на исходном красном `c9be893`). Все 35 AC требования пройдены механической проверкой дословно по формулировкам из `content/30-requirements/2026-08-09-test-harness-taxonomy-and-doc-paths.md`. Архив `tests/gramax/archive/**` подтверждён неисполняемым (grep по агрегаторам + побайтовая сверка 62 файлов с историей) и не участвует в счёте. Единственный непокрытый автоматикой пункт — позитивный прогон `verify.sh` с реальным вызовом `gramax:mermaid` — не блокирует merge: он не входит ни в один AC требования как обязательный для `--full`, статическая половина того же контракта покрыта и зелёная, а процедура ручной проверки описана и передаётся дальше как smoke-задача (аналогично прецеденту `mermaid-file-based` QA-отчёта 2026-05-12). Известные ограничения — разобраны, неблокирующие, задокументированы выше для следующего цикла.

**Передача BA:** статус — **merge**. Единственный опциональный follow-up вне AC этого требования — ручной smoke `verify.sh` с реальным вызовом `gramax:mermaid` (не блокер, см. «Не покрыто автоматикой», п.1).

---

## Постпроверка

`bash scripts/check.sh --fast` после записи этого отчёта — **PASS** (`RESULT: PASS`, содержательный вывод: whitespace OK, JSON OK, `content/: OK`, `Errors: 0 | Warnings: 0`).
