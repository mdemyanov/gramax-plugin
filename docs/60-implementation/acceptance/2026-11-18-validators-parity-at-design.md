---
title: "Приёмка (BA-acceptance): паритет офлайн-валидаторов с модулем «Проверка на ошибки»"
order: 11
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# Приёмка (BA-acceptance): паритет офлайн-валидаторов с модулем «Проверка на ошибки»

**Опоры:** `docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md`,
`docs/00-project/adr/0024-validators-error-check-parity.md`,
`docs/40-architecture/2026-11-18-validators-parity-design.md`,
`tests/gramax/catalog-validator/README.md`,
`plugins/gramax/scripts/tests/test_validators_parity.py`

**Роль:** BA-acceptance gate — проверка AC-152…AC-163 и FR-151…FR-157 требования против
**реализованного** кода валидатора (не против обещаний дизайна), с независимым повторным
исполнением буквальных проверок и вердиктом.
**Дата приёмки:** 2026-11-18
**Требование:** [Паритет офлайн-валидаторов плагина с модулем проверки ошибок приложения](../../30-requirements/2026-11-18-validators-error-check-parity-requirement.md) (AC-152…AC-163, FR-151…FR-157)
**ADR:** [0024-validators-error-check-parity](../../00-project/adr/0024-validators-error-check-parity.md) (коды — Решение 1, строгость — Решение 2, `diagramTags` — Решение 3, W034 — Решение 4, lucide — Решение 5)
**Дизайн:** [2026-11-18-validators-parity-design](../../40-architecture/2026-11-18-validators-parity-design.md) (план правок по FR, контракт с QA-author, миграция)
**Реализация:** коммит `6d43b7d` — `plugins/gramax/gramax-tags.json` (schemaVersion 2, ключ `diagramTags`, `plant-uml`/`bpmn` в `selfClosingTags`), `plugins/gramax/scripts/lib/md_link_parser.py` (параметризованный матчер), `plugins/gramax/scripts/validate_structure.py` (`check_diagrams` по членству, новый `check_icons` + W035, `known_tags` из обоих контрактов, фикс `_UNSUPPORTED_HTML_RE`), новый `plugins/gramax/scripts/tests/test_validators_parity.py`
**QA-отчёт:** [QA Report — паритет валидаторов](../test-reports/2026-11-18-validators-parity-qa-report.md) — независимый прогон, рекомендация **accept** (принята как вход, не как замена собственной проверке)
**Suite:** `tests/gramax/catalog-validator/` — `ac-025`…`ac-036`, один-к-одному на AC-152…AC-163 (карта — `README.md:199-210`); `ac-001`…`ac-024` — регрессионный пласт
**Метод:** каждый AC — проверка из требования, свидетельство реализации (файл:строка), собственный дословный прогон команды AC на собственных фикстурах в `/tmp`, вердикт PASS/FAIL. Каждый FR — implemented / partially / not implemented со свидетельством. Отклонения дизайн↔реализация классифицируются: accepted-deviation (с основанием) или дефект.

---

## Summary

| Метрика | Значение |
|---|---|
| AC | **12 pass / 0 fail** (AC-152…AC-163) |
| FR | **7 implemented / 0 partial / 0 not implemented** (FR-151…FR-157) |
| NFR | NFR-065/066/067 satisfied; NFR-068 — код-половина satisfied, CHANGELOG-часть отложена (Находка 1); NFR-069 N/A |
| Отклонения | 3 accepted-deviation, 0 дефектов (развод — раздел «Находки») |
| Гейты | Backlog-closure `✓ n/a`; Breaking-change-guide `✓ n/a`; Downstream-test-touch `N/A` |
| Вердикт | **accept** (блокеров нет; release-действия PM/Tech-writer — в конце) |

Собственные прогоны BA на момент приёмки (финальное дерево `4ba3202`):

- `bash tests/gramax/catalog-validator/run.sh` → rc=0, **36/36** (`All 36 AC tests passed.`);
- `uv run pytest plugins/gramax/scripts/tests/ plugins/gramax/scripts/lib/` → **33 passed**, rc=0;
- `bash scripts/check.sh --fast` → rc=0, `Errors: 0 | Warnings: 6`, `RESULT: PASS` (все шесть warnings — предсуществующие TPL-69 в досинтезных файлах вне окна волны, как зафиксировано QA-отчётом);
- собственные фикстуры в `/tmp` (композитная «паритет» и «пустой сбор») — формулы AC-152…AC-161 исполнены дословно, счётчики в разделе «AC coverage».

Замечание о механике: первый прогон suite в этой сессии (до PM-коммита `4ba3202`) дал 35/36 —
красным был только `ac-036` по env-причине (два незарегистрированных QA-отчёта параллельных
потоков → C1 в композитном гейте; классификация и разведение — в «Хронике сессии»).

---

## AC coverage (AC-152…AC-163)

Каждый AC закрыт ровно одним stub'ом suite (`ac-025`…`ac-036`, соответствие 1:1 по
`README.md:199-210`). Колонка «Прогон BA» — мой собственный дословный прогон формулы из
требования (фикстуры `/tmp/ba-accept-fixtures/`, вызов
`uv run plugins/gramax/scripts/validate_structure.py`), не пересказ QA-отчёта.

| AC | Проверка из требования (предмет) | Свидетельство реализации | Прогон BA (дословная формула) | Вердикт |
|---|---|---|---|---|
| AC-152 (диаграммы, позитив) | битые цели `missing.mmd`/`missing.puml`/`missing.bpmn` упомянуты в выводе | матчер `md_link_parser.py:24-30,99-104`; `check_diagrams` `validate_structure.py:732-754` | каждая из трёх целей упомянута ровно 1 раз, rc=0 | **PASS** |
| AC-153 (диаграммы, негатив) | существующие цели всех четырёх тегов → `grep -icE 'W031\|диаграмм'` → 0 | членство `target_type not in diagram_set` (`:745`) | `0` | **PASS** |
| AC-154 (regression guard drawio) | `bash ac-015-diagram-broken.sh && echo PASS` | W031-семантика сохранена, сообщение аддитивно (`:750-754`) | `PASS` | **PASS** |
| AC-155 (иконки, позитив) | `<icon code="my-custom-icon"/>` без `.icons/` → находка с кодом | `check_icons` `:760-786`, W035 с кодом и ожидаемым путём (`:783-786`) | `ba-check-icon` найден 1 раз: `W035: … код "ba-check-icon" → ожидается .icons/ba-check-icon.svg` | **PASS** |
| AC-156 (иконки, негатив) | та же фикстура + `.icons/<код>.svg` → НЕ находит | резолв `root/.icons/<code>.svg` (`:781`) | после добавления файла — `0` упоминаний кода | **PASS** |
| AC-157 (иконки, граница lucide) | `<icon code="lucide-zap"/>` без `.icons/` → находки нет | skip по префиксу (`:779-780`) | `lucide-zap` — `0` упоминаний | **PASS** |
| AC-158 (W034, контракт-паритет) | `<view defs>` + существующая `<mermaid path="./ok.mmd"/>` → `W034` НЕ находит | `known_tags ⊇ selfClosingTags ∪ pairedTags` (`:654-657`) | `W034` в фикстуре ровно 1 — и это `fancy-widget-x`; `view` молчит | **PASS** |
| AC-159 (W034, неизвестный дефисный тег) | `<fancy-widget-x/>` вне контрактов → `W034` находит | `_UNSUPPORTED_HTML_RE` дефис + `/?` (`:802`) | `W034: неподдерживаемая разметка: <fancy-widget-x>` — находит (дефис и голый `/>` обе ветки) | **PASS** |
| AC-160 (одна находка на дефект) | битая `<mermaid path="./missing.mmd"/>` → `grep -c 'missing.mmd'` → 1 | структурная демаркация: `plant-uml`/`bpmn`/`mermaid` в `selfClosingTags` (`gramax-tags.json:4`) → W034 молчит | ровно `1` | **PASS** |
| AC-161 (уровень по умолчанию) | единственный дефект — битая цель: exit 0 без флагов, exit 1 с `--strict` | warning-уровень (`:750`), эскалация `--strict` (`main:896-906`) | `EXIT_DEFAULT=0`, `EXIT_STRICT=1` | **PASS** |
| AC-162 (догфудинг) | `grep -E 'W034: .*<(view\|mermaid\|…)>'` на живом `docs/` — пусто | вычисляемый known-набор (`:652-663`) | grep пуст (rc=1); полный инвентарь W034 по `docs/` — ровно 3 прозаические находки `<home>`, `<file>`, `<raw>`; обе живые ложные факта 7 устранены | **PASS** |
| AC-163 (композитный) | `bash scripts/check.sh --fast` зелёный | — | rc=0, `Errors: 0 \| Warnings: 6`, `RESULT: PASS`; stub `ac-036` на финальном дереве — PASS | **PASS** |

Дополнительно к формуле требования (проверено по коду и pytest): периметр иконок — только
тела статей (`_collect_md_files`, `:775`), `properties.icon` не читается (FR-154); пустой сбор
→ ноль находок — моя «пустая» фикстура без `<icon>` и без `.icons/` дала 0 упоминаний
`W035|иконк` (FR-155); границы — pytest `NestedDocRootOwnIconsTests` (иконка вложенного
root — против своего `.icons/`) и `XlucidePrefixBoundaryTests` (`xlucide-zap` — кастомный).

---

## FR coverage (FR-151…FR-157)

| FR | Требование (кратко) | Реализация | Статус |
|---|---|---|---|
| FR-151 | существование целей `<mermaid>`/`<plant-uml>`/`<bpmn>` в семантике drawio (W031) | `parse_md_resources(root, diagram_tags)` — `md_link_parser.py:67,99-104`, `target_type` = имя тега; `diagram_tags` из контракта (`validate_structure.py:637`); членство + W031 с именем тега (`:743-754`); `in_scope` граница (`:747-748`) и per-root вызов (`:709`) унаследованы; прокидка в `_parse_resources` (`:271-280`) | **implemented** |
| FR-152 | ровно одна находка на битую цель, без дубля W034 | структурно: все четыре диаграммных тега в `selfClosingTags` (`gramax-tags.json:4`) → `known_tags` (`:654-657`) → W034 молчит; замер — счётчик `1` | **implemented** |
| FR-153 | кастомный код против `.icons/<code>.svg` своего root; `lucide-` не резолвится | `check_icons` (`:760-786`): skip `lucide-` (`:779-780`), `expected = root/.icons/<code>.svg` (`:781`), W035 называет код и ожидаемый путь (`:783-786`); ADR-0020 per-root — pytest-класс `NestedDocRootOwnIconsTests` | **implemented** |
| FR-154 | периметр — только `<icon code>` в статьях; `properties.icon` вне | источник вхождений — только `_collect_md_files` + `_ICON_RE` (`:757,775-777`); чтения frontmatter/`.doc-root.yaml` иконок нет в коде | **implemented** |
| FR-155 | отсутствие `.icons/` само по себе — не дефект | проверка существования каталога в коде отсутствует; пустая фикстура BA — 0 находок `W035\|иконк` | **implemented** |
| FR-156 | тег из контрактов не получает W034; набор вычисляется, не литерал | `known_tags` = `{"drawio"} ∪ diagramTags ∪ selfClosingTags ∪ pairedTags ∪ killerTags ∪ allowlistedTags` (`:652-663`) из обоих JSON; деградация повреждённого контракта — error через `load_json_contract` | **implemented** |
| FR-157 | дефисные имена подпадают под W034 наравне с простыми | `_UNSUPPORTED_HTML_RE = <(?!/)([a-z][a-z0-9-]*)(?:\s[^>]*)?/?>` (`:802`); истинные позитивы сохранены (автоссылка `<https://…>` невидима, закрывающие отсечены — ассерты stub `ac-032`) | **implemented** |

**NFR:** NFR-065 (офлайн) — satisfied: только regex + файловая система, сетевых обращений и
вызовов модели нет. NFR-066 (warning по умолчанию, `--strict` эскалирует) — satisfied:
замер AC-161 (0/1); новых флагов нет. NFR-067 (одна находка) — satisfied: замер AC-160.
NFR-068 (синхрон контрактов) — код-половина satisfied: `git show --stat 6d43b7d` —
`gramax-tags.json` + `md_link_parser.py` + `validate_structure.py` + `test_validators_parity.py`
одним коммитом; CHANGELOG-часть отложена — Находка 1. NFR-069 — N/A (офлайн-скрипт).

---

## Находки: отклонения дизайн↔реализация

| # | Находка | Классификация | Основание |
|---|---|---|---|
| 1 | Запись `Contract:` в `plugins/gramax/CHANGELOG.md` (schemaVersion 2, ключ `diagramTags`, код W035) в дереве отсутствует; Dev объявил перенос в PM-пакет в сообщении коммита `6d43b7d` («CHANGELOG Contract: — PM-пакетом») — буква NFR-068/ADR-0024 Решение 3 требует «тем же коммитом» | **accepted-deviation** | (а) Буква NFR-068 самого требования — про синхрон контракта тегов с кодом; эта половина satisfied одним коммитом `6d43b7d` (проверено `git show --stat`); требование CHANGELOG-запись словами не несёт — она в дизайне (§«Миграция» п.5) и ADR-0024 Решении 3. (б) Перенос явный (сообщение коммита), не молчаливый. (в) До release-коммита ничего не публикуется — потребители в промежутке не дезинформированы. (г) Прецедент: протокол приёмки export (Находка 3) классифицировал ту же отложенную release-поверхность как accepted-deviation. **Условие:** запись обязательна в едином release-коммите 4.7.0 — блокер релиза, не блокер этого вердикта |
| 2 | Version bump не сделан: `.claude-plugin/marketplace.json` и `plugins/gramax/.claude-plugin/plugin.json` — 4.6.0 | **accepted-deviation** | Плановое состояние на момент приёмки: ADR-0024 Решение 7 прямо назначает bump отдельным коммитом после реализации/приёмки; коллизию номера с ADR-0022/0023 согласует PM. В AC-152…163 не входит; действие Tech-writer/PM — см. «Действия вне гейта» |
| 3 | Точечные pytest-проверки матчера живёт в новом `test_validators_parity.py`, дизайн называл домом `test_validate_structure.py` | **accepted-deviation** | Дизайн сам оставляет «финальную нумерацию и фреймворк» исполнителю (§«Контракт с QA-author»); выделенный файл — разделение ответственности без контрактных последствий: 33 passed, прежние счёты pytest не изменились (проверено прогоном) |

**Не отклонения (констатируются для полноты):**

- **Lucide-реестр не поставлен** — не отступление от требования: полная валидация lucide-кодов
  прямо в Out of scope требования (открытый вопрос 1), граница «только форма префикса» —
  буква FR-153; решение закреплено ADR-0024 Решением 5 с критерием повторного открытия.
  Поведение соответствует: `lucide-zap` молчит, `xlucide-zap` резолвится (pytest).
- **Слепая зона «диаграммный тег с `path` без self-closing слэша» — ноль находок** —
  унаследована от drawio-семантики, которую FR-151 требует воспроизвести («в той же
  семантике, что действующая проверка drawio»); задокументирована дизайном (§FR-151/152,
  §Edge cases) и зафиксирована тестом `DiagramPathWithoutSelfClosingTests`. Устранение —
  отдельный вопрос, не этого изменения.

**Дефекты:** не обнаружены. Ни одно отклонение не нарушает ни одного AC, FR, BR-028, BR-012…BR-014.

---

## Гейты приёмки

| Гейт | Результат |
|---|---|
| Backlog-closure | `✓ n/a` — `scripts/check-backlog-closure.py` в дереве отсутствует |
| Breaking-change-guide | `✓ n/a` — `scripts/check-breaking-change-section.py` в дереве отсутствует |
| Downstream-test-touch | `N/A` — окно волны `9355b69^..HEAD` трогает `tests/gramax/catalog-validator/` только добавлениями (42 файла, 602 insertions, ноль модификаций; `git diff --name-only` по `ac-001`…`ac-024` — пусто); тесты закрытых эпиков не тронуты |

Вердикт по правилу: каждый AC покрыт (12/12), тесты зелёные (собственный прогон suite 36/36,
pytest 33, композит rc=0), гейты pass/`n/a` — **pass**.

---

## Хроника сессии (env-событие, не дефект продукта)

Первый прогон suite в этой сессии (дерево `4109b8c` + незатреканные QA-отчёты двух
параллельных потоков) — 35/36, красный только `ac-036`: внутренний `check.sh --fast` ловил
C1 (файл не зарегистрирован в `test-reports/_index.md`) на файлах, не принадлежащих потоку
validators-parity. Посреди сессии PM-коммит `4ba3202` зарегистрировал оба отчёта; финальное
дерево: suite 36/36 (перепрогон BA), гейт `Errors: 0`, `ac-036` зелёный (точечный прогон BA).
Полный цикл «красный → внешняя причина устранена чужим коммитом → зелёный» без единой правки
кода/тестов потока — та же env-классификация, что в QA-отчёте («Failed tests»); файлы потока
(`git show --stat 6d43b7d`) в логе гейта не упоминались.

## Действия вне гейта (не блокеры вердикта)

1. **PM (release-пакет, обязателен до release):** запись `Contract:` в
   `plugins/gramax/CHANGELOG.md` — schemaVersion 2, ключ `diagramTags`, `plant-uml`/`bpmn` в
   `selfClosingTags`, новый код W035 (Находка 1; наследие FR-041/NFR-003 ADR-0012).
2. **Tech-writer/PM (release-flow, ADR-0024 Решение 7):** bump `marketplace.json` и
   `plugin.json` 4.6.0 → 4.7.0 (коллизию с ADR-0022/0023 согласует PM), текстовая правка
   `description` записи `gramax`, запись в CHANGELOG.
3. **PM:** регистрация этого протокола в `docs/60-implementation/acceptance/_index.md` (до
   регистрации fast-гейт понесёт одну ожидаемую own-file C1 на этот файл).
4. **Ревью-остатки (осознанно не в этом изменении):** слепая зона «path без `/>`» — при
   расширении охвата парсера; вторая волна исследования `catalog/error-check` — категория
   «шапки» и имя апстрим-группы для расщепления `images` (открытые вопросы 5/6 требования).

## VERDICT

**accept** — 12/12 AC pass (каждый — собственный дословный прогон формулы требования на
собственных фикстурах BA или точечный прогон suite-стаба), 7/7 FR implemented,
NFR-065/066/067 satisfied (замеры 0/1 и счётчик «1» собственными прогонами), регрессия
исключена (прежние 24 AC suite, pytest-счёты, plugin-contract, живой `docs/`: W034 5→3,
ноль новых находок — независимо подтверждено), дефектов нет; три отклонения —
accepted-deviation с основаниями, оба release-элемента (CHANGELOG `Contract:`, bump 4.7.0)
— плановые действия PM/Tech-writer, вердикт не меняют, но до release обязательны.
