---
title: "QA Report qa-057 — полный прогон после инверсии раскладки content/ → docs/"
order: 11
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# QA Report qa-057 — полный прогон после инверсии раскладки content/ → docs/

**Опоры:** `docs/30-requirements/2026-11-17-docs-layout-inversion.md`,
`docs/00-project/adr/0021-docs-layout-inversion.md`, `scripts/check.sh`, `scripts/check-gramax.sh`

**Дата прогона:** 2026-11-17T22:37:35Z (лог координатора), классификация — 2026-11-18
**Дерево прогона:** HEAD `ad7f1a4` (конец цепочки миграции A→B→B2→C→D1→D2→D3→D4, 8 коммитов), дерево чистое
**Точки сравнения:** base `8b6332d` (старт Dev-цепочки), pre-payload `1939ae6` (до синков 2.22.0/2.23.0)
**Лог прогона:** `/tmp/full-run-1794955055.log` (`scripts/check.sh --full` + 11 сьютов `tests/gramax/*/run.sh`)
**Tester:** QA-runner (qa-057)
**Требование:** [Инверсия раскладки content/ → docs/](../../30-requirements/2026-11-17-docs-layout-inversion.md) (FR-124…130)
**ADR:** [0021-docs-layout-inversion.md](../../00-project/adr/0021-docs-layout-inversion.md) (Решения 1–7, Поправки A+B)
**Приёмочный suite требования:** `tests/gramax/docs-migration/` — 12/12 зелёный (в логе, строка 727–733; вне отказного множества)

Примечание о размещении и схеме. Дом отчётов `docs/40-testing/reports/` в этом дереве
не адаптирован (карты `docs/00-vision/scaffold-map.md` нет; `scripts/next-id.sh` нет) —
отчёт положен по живому прецеденту дерева, в `docs/60-implementation/test-reports/`
(пять соседних отчётов волны 4.2.x). Тип `Прочее` из контракта роли исключён из enum
коммитом D3 («триммирован до живых значений») — использован живой тип `Тест-отчёт`,
иначе отчёт сам стал бы находкой C5; свойство `Связанное требование` в схеме корня
не объявлено — ссылка на требование вынесена в эту шапку.

## Summary

Гейт `check.sh --full` — **FAIL**; `check.sh --fast` — PASS. Полный прогон сверх гейта
накрыл 11 сьютов; отказные — 4 (плюс shellcheck-шаг гейта):

| Suite | Passed | Failed | Примечание |
|---|---|---|---|
| `gate-gramax-full.sh` (`check.sh --full`) | — | FAIL | shellcheck + 4 сьюта ниже |
| `gate-gramax-fast.sh` (`check.sh --fast`) | — | PASS | NFR-004 держится |
| `tests/gramax/docs-migration` | 12 | 0 | приёмка эпика, зелёный |
| `tests/gramax/catalog-validator` | 23 | 1 | `ac-001` (2 ассерта) |
| `tests/gramax/cross-catalog-retraction` | 6 | 3 | `ac-003`, `ac-007`, `ac-008` |
| `tests/gramax/render-linter` | 19 | 2 | `ac-019`, `ac-021` (каскад) |
| `tests/gramax/nauta-integration` | 6 | 2 | `ac-002`, `ac-008` |
| `tests/gramax/plugin-contract` | 7 | 0 | зелёный |
| `tests/gramax/mermaid-adoption` | 10 | 0 | зелёный |
| `tests/gramax/writer-consumer-rules` | 11 | 0 | зелёный |
| `tests/gramax/link-form-resolver` | 8 | 0 | зелёный |
| `tests/gramax/link-form-migration` | 7 | 0 | зелёный |
| `tests/gramax/orphan-references` | 1 | 0 | зелёный |

Длительность в логе не фиксировалась. Артефакт прогона: `rc=0` в хвостовых секциях
персональных сьютов лога — это rc конвейера записи лога, а не rc `run.sh`; не читать
как «зелёный» (наблюдение к записи прогона, не дефект тестов).

## Regression analysis

Метод: для каждого отказа — красный-до/красный-после. Прогон тех же сьютов в
одноразовых worktree на `1939ae6` и `8b6332d` (worktree сняты после замера); shellcheck
гейта воспроизведён той же командой, что в `scripts/check-gramax.sh:117`
(`git ls-files '*.sh'` минус archive, `shellcheck -x -P SCRIPTDIR`). Whole-`tests/` не
запускался; `check.sh --full` на основном дереве не перезапускался — лог есть запись.

### Таблица красного-до/после (по точкам окна)

| Отказ | 1939ae6 | 8b6332d | ad7f1a4 | Класс |
|---|---|---|---|---|
| shellcheck-гейт (SC1125 ×3, SC2086, info-находки) | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing |
| nauta-integration `ac-002` | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing |
| nauta-integration `ac-008` | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing |
| nauta-integration `ac-007` | зелёный | КРАСНЫЙ | зелёный | переходный: литералы stub'ов docs-migration триггерили страж; снят D3 |
| catalog-validator `ac-001`/AC-010 (догфудинг) | зелёный | зелёный | КРАСНЫЙ | **migration-introduced** |
| catalog-validator `ac-001`/AC-011 | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing |
| render-linter `ac-019` | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing |
| render-linter `ac-021` | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing, каскад ac-002/ac-008 |
| cross-catalog-retraction `ac-003` | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing; мода отказа сменена цепочкой |
| cross-catalog-retraction `ac-007` | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing |
| cross-catalog-retraction `ac-008` | КРАСНЫЙ | КРАСНЫЙ | КРАСНЫЙ | pre-existing |

Ни один отказ эпика не является regression в строгом смысле (ни один не был зелёным
на `8b6332d` и не стал красным на `ad7f1a4`), кроме AC-010 — он и есть единственный
новый красный. Кандидатные атрибуции брифа проверены и в основном опровергнуты:
ни shellcheck SC1125, ни пины `scripts/check.sh`, ни ce4228d-диффы не изменились
2.22.0/2.23.0-синками (тексты байт-в-байт те же на `1939ae6`); синк 849e1da повлиял
опосредованно — 2.23.0 сделал ложной посылку ассерта `ac-008` («профилей в gramax нет»).

## Failed tests (details)

| ID | Suite / файл:строка | Класс + атрибуция | Свидетельство (команда → наблюдение) | Владелец фикса | Блок merge |
|---|---|---|---|---|---|
| F1 | shellcheck-гейт, `scripts/check-gramax.sh:117`; находки `scripts/role-postflight.sh:101,120,124`, `scripts/role-preflight.sh:173` | pre-existing; доставлен `bfc0aa7` (payload 2.9.0: role-скрипты с текстом после директивы + канон-гейт, сканирующий все .sh) | shellcheck на worktree `1939ae6` → те же SC1125 (error) ×3 + SC2086 (info) байт-в-байт | plugin-release (текст за директивой) или project-gate-config | нет (внешнее следствие, ADR-0021 «payload не трогается») |
| F2 | nauta-integration `ac-002-nauta-scripts-delivered.sh:24` (AC-10) | pre-existing; `bfc0aa7` заменил проектный `check.sh` каноном, маркер `gramax-marketplace` исчез | `grep -c gramax-marketplace scripts/check.sh` → 0 на всех трёх точках | PM-decision (посылка «check.sh — версия gramax» умерла вместе с каноном ADR-037) | нет |
| F3 | nauta-integration `ac-008-check-includes-validator.sh:22` (assert_no_grep `validate-profile.py`) | pre-existing; заголовок канона упоминает валидатор с `bfc0aa7`; 2.23.0 (`849e1da`) сделал посылку «профилей нет» ложной (доставка validate-profile.py, D3 `--profile classic`) | шапка `scripts/check.sh` содержит литерал на всех трёх точках; в логе шаг `▶ validate-profile.py` исполняется | PM-decision (ретирить/перепрофилировать ассерт) | нет |
| F4 | catalog-validator `ac-001-dogfood-clean-exit.sh` AC-010 | **migration-introduced**; переезд стора `90fb994` (C) + ре-ключ догфудинга на `docs/` `33dc36e` (D2); корень: `docs/overlays/` (пустышка с `8076732`, только `profiles/.gitkeep`) впервые попал в рекурсивный скан ADR-0020 | `uv run plugins/gramax/scripts/validate_structure.py docs` → exit 1, `ERROR docs/overlays missing _index.md`; на `1939ae6`/`8b6332d` тот же ассерт (`... content`) зелёный | **Dev-here** | **да** |
| F5 | catalog-validator `ac-001-dogfood-clean-exit.sh` AC-011 | pre-existing; вызов сьюта живёт в `scripts/check-gramax.sh:168` с `bfc0aa7` | `grep 'tests/gramax/catalog-validator' scripts/check.sh` → пусто на всех трёх точках | Dev-here (ре-ключ ассерта на `check-gramax.sh`) | нет |
| F6 | render-linter `ac-019-precommit-gate.sh` | pre-existing; вызов `validate_render.py` живёт в `scripts/check-gramax.sh:80` с `bfc0aa7` | `grep validate_render.py scripts/check.sh` → пусто на всех трёх точках | Dev-here (ре-ключ ассерта) | нет |
| F7 | render-linter `ac-021-existing-suites.sh` | pre-existing, чистый каскад F2+F3 | ассерт гоняет nauta-integration → те же 2 отказа | разрешается с F2/F3 | нет |
| F8 | cross-catalog-retraction `ac-003-disposition-and-source-untouched.sh` | pre-existing, мода сменена: до окна — «дифф непуст» (правки `fba407a`/`61f47b0`/`a1d5470` ещё в эпоху content/), после C+D2 — предусловие мертво: baseline `ce4228d` не знает путей `docs/` | `git cat-file -e ce4228d:docs/40-architecture/2026-08-11-writer-rules-disposition.md` → rc 128 «exists on disk, but not in ce4228d» | Dev-here (перепин baseline) + PM-decision (сверка августовского дрейфа) | да (страж после D2 семантически мёртв — защиты не даёт; запись Д2/Поправки 4 «пины переживают» опровергнута) |
| F9a | cross-catalog-retraction `ac-007-plugin-json-version.sh:30` | pre-existing; пин 4.2.1 протух на `5f64966` (release 4.3.0, август) | `jq -r .version` → `4.5.0`, ожидание `4.2.1` | PM-decision (ретирмент пина релизного момента) | нет |
| F9b | cross-catalog-retraction `ac-008-marketplace-json-sync-decision.sh` | pre-existing; ветка (а) мертва (ADR-0017 отклонил отсрочку), ветка (б) требует литерал 4.2.1 | вывод ассерта: `diff_empty=0, adr_defers=0; version_match=0 (marketplace=4.5.0, plugin=4.5.0), adr_authorizes=1` | PM-decision | нет |

Предыстория F9a/F9b: отчёт волны 4.2.1
(`docs/60-implementation/test-reports/2026-08-13-cross-catalog-retraction-qa-report.md`)
фиксировал их красными как «ожидаемое незакрытое состояние» (bump — задача
Tech-writer); bump до 4.2.1 отработал, но пины не были ретиррованы при последующих
релизах 4.3.0/4.4.0/4.5.0.

## Dev-fix list (чинится в дереве, точечные правки)

1. **F4 (обязателен).** Либо `docs/overlays/_index.md` минимальным фронтом
   (title/order/properties по схеме корня), либо `git rm -r docs/overlays/` — каталог
   несёт только `profiles/.gitkeep` и ничто его не читает (`validate-profile.py`
   смотрит в `templates/overlays/profiles/`). Решение пустышка-vs-индекс — за SA/PM,
   но красный должен уйти до merge.
2. **F5.** `tests/gramax/catalog-validator/ac-001-dogfood-clean-exit.sh`: сменить носитель
   ассерта AC-011 c `$ROOT/scripts/check.sh` на `$ROOT/scripts/check-gramax.sh`
   (вызов на строке 168).
3. **F6.** `tests/gramax/render-linter/ac-019-precommit-gate.sh`: тот же ре-ключ на
   `scripts/check-gramax.sh` (вызов на строке 80).
4. **F8.** `tests/gramax/cross-catalog-retraction/lib/baseline-commit.sh`: перепин
   `BASELINE_COMMIT` на пост-инверсионный sha (например, `ad7f1a4`) с новой шапкой
   «зафиксировано до правок Dev»; августовский дрейф диспозиции/требования вынести
   отдельным PM-решением (страж молча красный с эпохи 4.3.0).
5. **F2/F3 (после PM-решения).** Ассерты AC-10/no-grep перепрофилировать: F2 —
   проверять владение через `.nauta-gates.yaml` → `projectGates` → `check-gramax.sh`
   (фактический сигнал «гейты наши») вместо маркера `gramax-marketplace`; F3 —
   заменить no-grep на поведенческую проверку (`validate-profile.py` штатно отвечает
   «профилей нет — нечего валидировать» / профилю classic по Поправке B).
6. **F1 (альтернатива в дереве).** Если релиз nauta с починкой директив не близко —
   project-gate-config: исключить базисные (доставленные) файлы из списка shellcheck
   или поднять порог; учтить: SC1125 — severity error, порог `-S` его не спрячет.
7. **F9a/F9b (после PM-решения).** Ретирмент релизных пинов: заменить литерал `4.2.1`
   на инвариант `plugin.json == marketplace.metadata.version` (+ ADR-авторизация),
   либо `git rm` обоих ассертов с записью в RECORD.
8. **Регистрация этого отчёта.** Роль работала в режиме «read-only на отслеживаемые
   файлы», поэтому строка-ссылка в `docs/60-implementation/test-reports/_index.md`
   (order 11 подготовлен во фронте) не проставлена. Пока её нет, `validate-content`
   несёт ERROR «не зарегистрирована ссылкой…» (быстрый гейт красный на 1 ошибку) и
   WARNING «статья без входящих ссылок» — добавить ссылку первым же коммитом Dev.

## Recommendation

- [ ] merge
- [x] block + back to Dev
- [ ] re-run (flaky)

**Rationale:** единственный красный, введённый самой цепочкой миграции (F4 — догфудинг
`docs/`), блокирует merge; вместе с ним в один Dev-проход уходят дешёвые ре-ключи
ассертов F5/F6/F8. Остальные красные — pre-existing с `bfc0aa7`/`5f64966`, зафиксированы
с атрибуцией и не являются ни flaky (ни один тест не давал расходящихся прогонов),
ни env: блоком они быть не могут, но без PM-решений (F2/F3/F9) и релиза nauta (F1)
`--full` зелёным в этом дереве не станет — это объявленное внешнее следствие
(ADR-0021, «payload не трогается»).

**Вердикт: MERGE-BLOCKING — 1 (F4); NON-BLOCKING — 9 (F1, F2, F3, F5, F6, F7, F8*, F9a, F9b);**
`*` F8 рекомендован к тому же Dev-проходу, поскольку страж после D2 семантически мёртв.
