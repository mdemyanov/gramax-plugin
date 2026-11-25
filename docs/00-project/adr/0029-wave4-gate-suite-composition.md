---
title: "ADR-0029: Состав гейта и сюит волны-4 — shellcheck на пути стабов, живая сюита инвариантов раскладки, снятие report-режима, два неотданных гейта и остатки ревью волны-3"
order: 29
status: accepted
date: 2026-11-24
properties:
  - name: Тип контента
    value: [ADR]
  - name: Статус
    value: [Accepted]
  - name: Плагин
    value: [gramax, marketplace]
---

# ADR-0029: Состав гейта и сюит волны-4 — shellcheck на пути стабов, живая сюита инвариантов раскладки, снятие report-режима, два неотданных гейта и остатки ревью волны-3

**Status:** Accepted — ратифицировано PM 2026-11-24 по санкции владельца «автономно до push включительно»
(волна-4, решение D5): решения 1–5 приняты как написаны. Принято отклонение от ожидания брифа: исключения
`-e` shellcheck действуют только на файлы базиса, находки проектных стабов правятся до включения шага.
**Date:** 2026-11-24
**Plugin:** gramax / marketplace
**Опоры:** `docs/00-project/epics/2026-11-24-wave4-tails-genesis-tree.md`, `docs/00-project/adr/0027-full-gate-composition.md`,
`docs/00-project/adr/0011-test-harness-taxonomy.md`, `docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md`,
`scripts/check-gramax.sh`, `tests/gramax/gate-composition/ac-143-suite-statuses.sh`, `scripts/render-quality/probe.py`,
`plugins/gramax/scripts/migrate_nav_codespans.py`, `tests/gramax/comments/ac-132-comments-utf8-skip.sh`

## Context
Волна-4 закрывает хвосты гейта поверх ADR-0027 (D15 [Дерево решений генезиса: волна-4 — закрытие всех открытых хвостов, релиз 4.11.0](../epics/2026-11-24-wave4-tails-genesis-tree.md)).
Замеры 2026-11-24 на `f551d87` (чистый экспорт `git archive HEAD`): shellcheck зовётся один раз и только в `--full`
(`scripts/check-gramax.sh:169`; `git ls-files '*.sh'` минус архив: 336 → 269), а путь qa-author → Dev идёт через
`--fast`; живых ассертов инвариантов раскладки нет (OI-1 ADR-0027); report-режим мигратора вне гейта; два
инструмента ростера не доставлены; семь пунктов ревью волны-3 открыты. Повод Решения 1 — уроки журнала
(`docs/lessons-learned.md`, 2026-11-21 и 2026-11-23): стабы дважды дошли до полного гейта с lint-долгом. Требование волны-4
`docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md` (вне индекса на момент письма) несёт
FR-226…FR-230, FR-233, FR-234, NFR-086…NFR-088; здесь — техническая форма по карточкам `gramax-o0q.31`, `.32`, `.34`, `.45`, `.46`.

## Решение 1 — shellcheck на пути стабов: шаг `--fast` по изменённым и новым `.sh` (gramax-o0q.31)
Путь `--fast` в `scripts/check-gramax.sh` получает шаг 2.7 `==> shellcheck-changed` (после `render`, до блока `--full`); список дословно:
`{ git ls-files --others --exclude-standard -- '*.sh'; git diff --name-only --diff-filter=d HEAD -- '*.sh'; } | grep -v '^tests/gramax/archive/' | sort -u`.
Новый шаг и шаг `--full` `shellcheck` делят список одним правилом: 11 `.sh` базиса (`.nauta-scripts-basis.yaml`) —
`shellcheck -e SC1125 -e SC2001 -e SC2016 -e SC2086 -x -P SCRIPTDIR` (до исправления issue №42 — `scripts/check-gramax.sh:163`),
остальные 258 — `shellcheck -x -P SCRIPTDIR`. Исходы: список пуст → `OK: no changed shell files`; shellcheck нет →
`FAIL: shellcheck not installed — N изменённых .sh не проверены` (список непуст); список не собрался (ошибка git) →
`FAIL` с именем шага; есть находки → `FAIL: shellcheck issues (changed files)`; чисто → `OK: shellcheck clean (N changed)`.
Всё, кроме двух `OK`, ставит `FAILED=1`. Цена на чистом дереве: 0 вызовов shellcheck, 2 вызова git на `--fast`;
`--full` исполняет путь `--fast` 11 раз — 1 и 10 вложенных вызовов из 9 стабов (`git grep -nE 'bash .*scripts/check\.sh.* --fast' -- 'tests/gramax/**/*.sh' ':!tests/gramax/archive'` минус строки `#`/`echo`/`printf`/`pass_msg`).
Предусловие включения: `shellcheck -x -P SCRIPTDIR` по 258 проектным файлам без `-e` даёт 8 находок в 5 файлах `tests/gramax/` (6× SC2016, 2× SC2001) — `-e` действует на весь вызов и снимает их; правятся до включения шага.

## Решение 2 — живая сюита `tests/gramax/docs-layout-invariants/` (gramax-o0q.45)
Сюита плоская (ADR-0011 Решение 5): `ac-*.sh`, `run.sh` по glob, `README.md`. Пять стабов — копии архивных
оригиналов; имена читаются как цитаты `AC-003`…`AC-007` требования инверсии раскладки — новых определений нет.

| Стаб | Ассерт — дословная PASS-строка оригинала | Отличие копии |
|---|---|---|
| `ac-003-no-content-pointers.sh` | «литерал content/ вне исключений Решения 3 ADR-0021 не встречается» | строка 2; исключение самой сюиты → `./tests/gramax/docs-layout-invariants/*` |
| `ac-004-no-deleted-pointers.sh` | «указателей на удаляемые по FR-129 артефакты нет (RECORD учтён)» | строка 2; адрес исключения — ниже |
| `ac-005-gates-rekeyed.sh` | «гейты действуют на docs/, documentaryCircuit отсутствует, валидатор зелёный» | строка 2 |
| `ac-006-layout-map-resolves-docs.sh` | «карта раскладки адресует все шесть дома через docs/» | строка 2 |
| `ac-007-single-doc-root.sh` | «один doc-root docs/, модель свойств объединена, индекс поглотил роль корневого» | строка 2 |

Отличия от архива — 7 строк в 5 файлах: строка 2 (адрес, происхождение) и адрес собственного исключения в
`ac-003`, `ac-004` (дословно: `grep -qE "^tests/gramax/(archive/docs-migration|docs-layout-invariants)/"`).
Место в `--full` — сразу после `nauta-integration`: `==> docs-layout-invariants`,
`bash tests/gramax/docs-layout-invariants/run.sh`; хвост `cross-catalog-retraction` → `gate-composition` не
трогается. Замер на `f551d87` в чистом экспорте с кандидатом сюиты: 5 из 5 rc=0, shellcheck rc=0, 5 из 5 краснеют на подкладывании.

В архиве на месте (поочерёдно `bash tests/gramax/archive/docs-migration/ac-00N-*.sh`, N=3…7) 4 из 5 зелёные, `ac-004` красный структурно — rc=1, 37 попаданий, все внутри
`tests/gramax/archive/docs-migration/`. `ac-143-suite-statuses.sh` получает четыре ноги: `run.sh` живой сюиты
существует; в теле `--full` есть `bash tests/gramax/docs-layout-invariants/run.sh`; заголовок называет
`tests/gramax/docs-layout-invariants`; пять стабов на месте. Нога 6 не меняется, «17-я сюита» → «18-я» (`:6`,
`:84`); порядок сюит стаб не пришивает. `ac-147` — без правки; `ac-146` (`:58`, `:61`, `:97`) и `CLAUDE.md:49` — 18.
«Архив не менялся» судит приёмка (`git diff --stat <база>..HEAD -- tests/gramax/archive/` пуст), не сторож (Решение 1
ADR-0011 отверг техническую защиту архива).

**Поправка при исполнении (2026-11-24).** Живая сюита отличается от архива больше, чем на семь строк;
каждое отличие названо с основанием в её записи AT-design
(`docs/60-implementation/acceptance/2026-11-24-wave4-gates-at-design.md`, раздел «Отклонения»):
глоб `case` стаба `ac-003` записан одинарным (дословная пара давала SC2221); из живой копии `ac-003`
изъято исключение для скрипта, удалённого при инверсии раскладки (на него указывала сюита
`orphan-references`); правило класса 6 узнаёт токен локального корня потребителя вместо приватного
литерала (обезличивающий проход D8, ADR-0030); README живой сюиты написан заново под её пять стабов
(байт-копия несла литерал переехавшего каталога — `nauta-integration/ac-007`). Архив не тронут.

## Решение 3 — report-режим снят; спаны старой раскладки — вход точечного прохода, не гейт (gramax-o0q.32)
Report-режим `plugins/gramax/scripts/migrate_nav_codespans.py` в `--full` не входит и снимается с планов; скрипт
остаётся ручным диагностом: Решение 3 ADR-0016 (`:139` — классификация не становится автоматической проверкой)
и D11 дерева волны-4 («advisory NAV-гейт» не строится). Замер:
`python3 -B plugins/gramax/scripts/migrate_nav_codespans.py docs` → rc=1, `To-migrate: 26`, `SELF: 22`,
`SUBJECT: 203`, 15 файлов. Старую раскладку мигратор не видит по построению: `:345` — регекс по имени корня,
`:323`, `:337` — NAV требует существующей цели. Механизм — не новый гейт: кандидаты перечисляет
``/usr/bin/grep -rlE '`content/[^` ]+\.md`' docs --include='*.md'`` (34 файла, 307 спанов); сужение «файл вне
датированных записей, строка не класса 6, цель существует под `docs/`» даёт 19 файлов, 232 спана — надмножество
набора FR-235 (141 спан внутри корпус-аудита): существование цели не отличает своё от чужого, суждение остаётся
за точечным проходом, после него — контрольный прогон того же перечня. Живой текст вне файловых классов держит копия
`ac-003`, внутри — Решение 4 ADR-0021; роста нет: из 81 коммита после `ad7f1a4` (`git rev-list --count ad7f1a4..HEAD`)
такие строки (`git log -G`) затронул один — `563f005`, 3 строки о чужом каталоге.

## Решение 4 — два неотданных инструмента: «не усыновлять» (gramax-o0q.34)
Оба исхода — «не усыновлять», гейт остаётся n/a (`scripts/check.sh:882-885`, объявленное молчание).
`check-backlog-closure.py` судит markdown-бэклог с заголовками `###`/`####`; tracked-файла с `backlog` в имени 0
(`git ls-files | grep -i backlog`), стор задач локальный и исключён (`git check-ignore -v .beads`; `git ls-files .beads`: 0) — гейт
судил бы несохранённое состояние. `check-breaking-change-section.py` не доставляется и в ростере не вызывается
(`scripts/check.sh:2967-2975`, `:3041`). Блок «Breaking change» в `plugins/gramax/CHANGELOG.md`
(`grep -n 'Breaking change' plugins/gramax/CHANGELOG.md`: 5 вхождений, 2 заголовка `###` — в записях 4.10.0 (Minor) и 4.0.0 (Major); у 3.0.0 и 2.0.0 — фраза в прозе) — суждение о том, что заметит потребитель: in-tree сторожа нет, advisory-применение остаётся ручной проверкой приёмки.
Триггеры возврата: ADR, резервирующая следующий Major (прецедент ADR-0018), добавляет ногу `gate-composition`
«версия `x.0.0` ⇒ запись `## x.0.0` несёт литерал Breaking change»; для backlog — tracked-бэклог или смена стора.

## Решение 5 — технические вердикты по ревью волны-3 (gramax-o0q.46)
| № | Вердикт | Дословная цель | Основание |
|---|---|---|---|
| 1 | правка | `_probe_row` (`scripts/render-quality/probe.py:185-192`): проверка `expect is None` — первой, до чтения `expect["tier0"]`; строка расхождения с нотой «expect.json не читается», rc=1 | при `expect=None` — `TypeError 'NoneType' object is not subscriptable` |
| 2 | шаг снят | `submodule status` (`scripts/check-gramax.sh:182-189`; заголовок `:11`, `:103`) удаляется | `git submodule status` → 0 строк, `.gitmodules` нет; ни один стаб шаг не держит |
| 3 | усилить | `tests/gramax/plugin-contract/ac-140-readme-version-docstring.sh:76`: `th[^.]*warn` или `warn[^.]*th` → `<th>[^.]*warn` или `warn[^.]*<th>` | строка без тега («Without any doubt the linter may warn here») проходит сегодня (1), после — 0; докстринг — те же 2 строки |
| 4 | правка | `tests/gramax/gate-composition/ac-149-changelog-calibration.sh:68`: rc захватывается; нога падает при rc ∉ {0, 1} и при rc=1 без строки `SIGNAL` | код 1 — мягкий «неопределим» прибора; `python3 -B scripts/check-content-actuality.py` на HEAD: rc=1, 94 строки SIGNAL |
| 5 | правка | `tests/gramax/gate-composition/ac-144-dogfood-validators.sh:58`: `python3 -B` → `uv run`, как у гейта (`scripts/check-gramax.sh:112`, `:125`) | `uv run python --version` — 3.12.10, `python3 --version` — 3.15.2 с pyyaml из user-site |
| 6 | переподпись | заголовок `tests/gramax/comments/ac-132-comments-utf8-skip.sh` (`:3-5`; `grep -c 'AC-133'` — 13) и `tests/gramax/comments/README.md:16` → «AC-132 (FR-212), comments-нога»; имя файла и ADR-0027 не меняются | определения (`docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md:213-216`), имя при рождении `49b2f37`, `docs/60-implementation/acceptance/2026-11-23-wave3-at-acceptance.md:71` — все за 132; Решение 5 ADR-0027 (`:98`) верно |
| 7 | stderr | `refuse()` (`scripts/render-quality/probe.py:46-49`) пишет баннер в stderr; stdout при rc=2 пуст | `uv_named_refusal` (`scripts/render-quality/probe.sh:34-36`) уже в stderr; стабы `ac-106`, `ac-107`, `ac-126`, `ac-142` читают только stderr |
| 8 | issue | `scripts/role-postflight.sh:80-87` — payload базиса, в дереве не правится | вход issue ниже |

## Входы issues в репозиторий плагина `nauta` (пакет D13; имя репозитория не приводится — ADR-0014)
- **Постфлайт ролей не диспетчеризует по типу файла.** Что: шаг 3 (`scripts/role-postflight.sh:80-87`) подаёт
  любой именованный файл в `uv run --with pytest pytest <файл> -q`. Дефект (замер):
  `bash scripts/role-postflight.sh tests/gramax/gate-composition/ac-150-identifier-registry.sh` →
  `run-quiet: rc=4`, `ERROR: not found: <репозиторий>/tests/…ac-150-identifier-registry.sh` (файл существует), `постфлайт: rc=1 — check.sh=0 validate-content=0 pytest=4`.
  Исправление: `*.sh` → `bash <файл>` (rc в свёртку), `*.py` → pytest, иное расширение → именованный отказ по образцу `:59-62`.
- **Шапка `scripts/check.sh` обещает невыданный гейт:** `:14`, `:57-61` объявляют `check-backlog-closure.py`
  частью `--full`, `:2584` объявляет его NOT-DELIVERED. Исправление: привести строки режима к объявлению.

## Целевой состав `--full`
| Часть | Метка `==>` | Что исполняет | Волна-4 |
|---|---|---|---|
| `--fast` | whitespace, json, content, render | шаги 1–2.6 без изменений | — |
| `--fast` | shellcheck-changed | shellcheck изменённых и новых `.sh` | новый шаг |
| `--full` | validate-structure, validate-comments, shellcheck | 2 валидатора `docs/` и 269 живых `.sh` | `-e` — только 11 файлам базиса |
| `--full` | submodule status | — | снят |
| `--full` | 18 сюит по порядку | orphan-references · nauta-integration · docs-layout-invariants · plugin-contract · catalog-validator · comments · mermaid-adoption · writer-consumer-rules · link-form-resolver · link-form-migration · export-skill · plantuml-bpmn · writer-sync-470 · writer-tail-480 · render-linter · render-quality · cross-catalog-retraction · gate-composition (`bash tests/gramax/<имя>/run.sh`; writer-tail-480 — циклом по glob) | +`docs-layout-invariants` |

## Поправки к принятым ADR

### Поправка к ADR-0011 (часть 1)
«Живые ассерты … выделяются … до переезда»: для `docs-migration` выделение выполнено после переезда копированием
(Решение 2); критерий «природа ассерта» и запрет правки архива действуют дословно.
### Поправка к ADR-0027 (часть 2)
Баннер `REFUSAL <КОД>: <подсказка>` пишется в stderr; stdout при rc=2 пуст.
### Поправка к ADR-0027 (часть 3 и «Целевой состав»)
OI-1 закрыт: живые ассерты выделены в `tests/gramax/docs-layout-invariants/` (Решение 2). Состав: 17 → 18 сюит,
`submodule status` снят, `-e` сужен до файлов базиса; report-режим мигратора в состав не входит.

## Consequences
- **Положительные:** стаб с находкой shellcheck ловится в постфлайте роли и в pre-commit; инварианты раскладки
  снова под сторожем; ни один шаг гейта не зелёнеет без предмета.
- **Совместимость:** `--fast` требует shellcheck только при непустом списке изменённых `.sh`; `--full` длиннее на
  одну сюиту; баннер отказа прибора сменил поток. **Trade-offs:** `-e` снимает 18 находок в 4 файлах базиса до
  их исправления выше по потоку; копия `ac-005` повторяет вызов валидатора шага 2.5.
- **NFR-мэппинг:** NFR-086 — Решение 2 (5 из 5 зелёные, 5 из 5 краснеют, архив не тронут); NFR-087 — Решения 1,
  3, 4, 5 (ни один шаг не снят без названного исхода); NFR-084, NFR-085 волны-3 — шаги офлайн, ассерты не ослаблены;
  NFR-088 — имена внутренних репозиториев не приводятся.

## Alternatives Considered
- Локальная команда в README сюиты — отклонена: уроки [Lessons Learned — gramax marketplace](../../lessons-learned.md) 2026-11-21 и 2026-11-23 — ручной прогон провалился дважды.
- shellcheck всех 269 файлов в `--fast` — отклонён: 269 файлов × 11 прогонов пути `--fast` ради нуля изменений.
- Шаг `submodule status` с `FAILED=1` — отклонён: предмета нет (0 submodules).
- Живая сюита под именем `docs-migration` — отклонена: нога 4 `ac-143` держит отсутствие старого каталога.
- Report-режим шагом `--full` — отклонён: Решение 3 ADR-0016 (`:139`, `:269-271`) и D11.
- Переименовать стаб `ac-132` в `ac-133` — отклонено: три цитаты RECORD повисли бы (`docs/60-implementation/acceptance/2026-11-23-wave3-plugin-at-design.md:59`, `:216`;
  `2026-11-23-wave3-at-acceptance.md:71` там же).

## Связанные артефакты
- требования: [Волна-3 — релиз 4.10.0: калибровка контрактов валидаторов, гейтов и хвостов гигиены](../../30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md);
  [Инверсия раскладки документации — `content/` → `docs/` с зачисткой исторических артефактов](../../30-requirements/2026-11-17-docs-layout-inversion.md); [Волна-4 — релиз 4.11.0: контракты валидаторов и резолвера, гейты и сюиты](../../30-requirements/2026-11-24-wave4-contracts-gates-requirement.md) (вне индекса на момент письма)
- поправляет в части: [ADR-0011: Таксономия test harness tests/gramax и гейт doc-paths](0011-test-harness-taxonomy.md) (Решение 1), [ADR-0027: Полный гейт `--full` релиза 4.10.0 — живая нога вне гейта, именованные отказы, догфудинг валидаторов, статус сюит и удаление overlay-тулинга](0027-full-gate-composition.md) (Решения 2, 3; состав)
- применяет: [ADR-0016: Контракт формы ссылки на артефакт — резолвер гейта и временный протокол при расхождении с nauta](0016-link-form-contract.md) (Решение 3), [ADR-0021: Инверсия раскладки документации — переезд `content/` → `docs/`, слияние doc-roots, зачистка исторических артефактов](0021-docs-layout-inversion.md) (Решения 3, 4)
- затрагивает (файлы Dev): `scripts/check-gramax.sh`, `scripts/render-quality/probe.py`, `CLAUDE.md:46-51`; `tests/gramax/docs-layout-invariants/` (новая);
  `tests/gramax/gate-composition/` (`ac-143`, `ac-146`, `ac-149`), `tests/gramax/plugin-contract/`, `tests/gramax/comments/`, `tests/gramax/render-quality/` (стабы отказа); 5 файлов с 8 находками shellcheck
