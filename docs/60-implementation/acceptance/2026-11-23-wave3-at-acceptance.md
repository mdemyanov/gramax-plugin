---
title: "Приёмка (BA-acceptance): волна-3 — релиз 4.10.0, калибровка контрактов валидаторов, гейтов и хвостов гигиены — accept (23 PASS / 0 N/A / 0 FAIL)"
order: 23
status: draft
date: 2026-11-23
plugin: gramax
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Draft]
  - name: Плагин
    value: [gramax]
---

# Приёмка (BA-acceptance): волна-3 — релиз 4.10.0, калибровка контрактов валидаторов, гейтов и хвостов гигиены — accept (23 PASS / 0 N/A / 0 FAIL)

**Опоры:** `docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md`, `docs/00-project/adr/0026-validator-contracts-engine-pin.md`, `docs/00-project/adr/0027-full-gate-composition.md`, `docs/00-project/epics/2026-11-23-wave3-contracts-gates-genesis-tree.md`, `docs/60-implementation/acceptance/2026-11-23-wave3-plugin-at-design.md`, `docs/60-implementation/acceptance/2026-11-23-wave3-gates-at-design.md`, `docs/60-implementation/test-reports/2026-11-23-wave3-qa-report.md`, `plugins/gramax/CHANGELOG.md` (раздел 4.10.0 — текст релиза в рабочем дереве)

**Роль:** BA-acceptance gate волны-3 эпика «калибровка контрактов валидаторов, гейтов и хвостов гигиены» (релиз 4.10.0). Проверка AC-129…AC-151 против реализации по букве требования; вердикт выдаёт gate, ничего не правит — артефакты сессии: этот документ и его индексная строка в `acceptance/_index.md`.

**Дата приёмки:** 2026-11-23

**Требование:** [Волна-3 — релиз 4.10.0: калибровка контрактов валидаторов, гейтов и хвостов гигиены](../../30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md) (FR-208…FR-221, AC-129…AC-151, NFR-084…085; BR-025…BR-027; режим волны — автономно до push включительно, D6 дерева волны-3)

**Решения:** [ADR-0026](../../00-project/adr/0026-validator-contracts-engine-pin.md) — дословные целевые значения пяти контрактов по движку `48592b36`; [ADR-0027](../../00-project/adr/0027-full-gate-composition.md) — состав `--full`, именованные отказы живой ноги; [дерево волны-3](../../00-project/epics/2026-11-23-wave3-contracts-gates-genesis-tree.md) (D1–D8)

**AT-design:** [стабы контуров валидаторов и навыков (AC-129…AC-140, AC-148, AC-151)](2026-11-23-wave3-plugin-at-design.md) — карта AC → стаб и таблица ремонтов стабов; [стабы гейта и хвостов гигиены (AC-141…AC-147, AC-149, AC-150)](2026-11-23-wave3-gates-at-design.md)

**Реализация:** окно `43435c7..2d5b339` (HEAD приёмки `2d5b339`): `d6ccab7` — сквозные правки валидаторов (реестр кодов иконок, именованная находка E036 на битом UTF-8, маскирование блоков HTML); `7d8001c` — регрессия вложенных html-блоков (поймана замером «после», стабы `ac-137b` в двух сюитах) плюс правки независимого ревью (перенумерация, shellcheck, BR-011 → BR-028, ADR-0026 Решение 8); `07c05c0` — два тестовых перевода по первому полному прогону (`ac-134`, `ac-105`); `2d5b339` — документарный (QA-отчёт qa-057, пять уроков, поправка ADR-0026, докстринг генератора реестра). Тексты релиза 4.10.0 (`plugins/gramax/CHANGELOG.md`, `plugins/gramax/README.md`, `plugins/gramax/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`) — в рабочем дереве и ждут релизного коммита; между зелёным прогоном координатора (`07c05c0`) и HEAD правки только документарные и докстринг `scripts/gen-gramax-lucide-icons.py` — код валидаторов, контракты и сюиты не менялись.

**QA-отчёт:** [qa-057 — два полных прогона `--full`](../test-reports/2026-11-23-wave3-qa-report.md): прогон 1 (`7d8001c`) rc=1 — два отказа класса test-adaptation; прогон 2 (`07c05c0`) rc=0, `RESULT: PASS`, все 21 шаг зелёные (217 AC-ног по 17 сюитам), хвостовой `--fast` PASS; регрессий нет.

**Метод:** каждый AC — тест, реализация, результат. Все стабы волны-3 и переведённые ноги исполнены моей рукой 2026-11-23 (rc=0), три валидатора на `docs/` и три pytest-файла — моей рукой. Полный гейт `--full` и агрегаторы сюит при приёмке не исполняются BA — свидетельства зелёного `--full`: сырые логи координатора `/tmp/gramax-full-1.txt` (811 строк, HEAD `7d8001c`, rc=1) и `/tmp/gramax-full-2.txt` (803 строки, HEAD `07c05c0`, rc=0), прочитанные целиком qa-057. Числа корпуса сравнения (живой каталог, 766 страниц, `syntax: XML`; далее — «корпус сравнения») — замер координатора: корпус приватный, стабами не читается, в гейте цифр нет. Словарь вердиктов: **pass** / **N/A** (с основанием) / **fail**. Тишины-скипа нет.

**Вердикт:** **pass** — 23/23 AC: 23 PASS / 0 N/A / 0 FAIL.

## Breaking change

**Что потребитель observes иначе после 4.10.0** — по блоку «Breaking change» раздела 4.10.0 в `plugins/gramax/CHANGELOG.md` и блокам «Совместимость» ADR-0026/ADR-0027. Semver — Minor: навыки не добавлялись и не удалялись, `mcpServers` не менялись. Коды выхода валидаторов не меняются (ADR-0026) — кроме двух именованных отказов прибора, введённых ADR-0027.

- **Каталог без `language`** в `.doc-root.yaml` перестаёт давать rc=1 («missing field: language»); присутствующее поле неверного типа по-прежнему ERROR.
- **`properties` в `_index.md` подпапки** больше не ERROR (на корпусе сравнения — 43 ложных); взамен применяются V3–V5 (необъявленное свойство, значение вне enum, плоская нотация) — во внешних каталогах возможны новые истинные находки; `_index.md` корня вне проверки.
- **Повторный ID комментария** — не ошибка: «duplicate comment id» уходит, вместо него информационная строка с позициями; rc и `--strict` не меняются; `--delete` снимает все позиции ID.
- **Коды иконок**: встроенные коды Lucide (голый kebab-case) перестают давать W035; код с префиксом `lucide-` без файла в `.icons/` даёт W035 с подсказкой убрать префикс; `writer` пишет коды без префикса (ADR-0024 Решение 5 и BR-013 — superseded в части формы).
- **XML-таблицы**: `table`/`tr`/`td` больше не дают W034 (под `--strict` таблицы перестают краснеть); незакрытый тег таблицы по-прежнему одна находка — ERROR баланса от `validate_render.py` (BR-027).
- **Битый UTF-8**: вместо traceback и обрыва обхода — именованная находка (`E036`; `ERROR L0` у рендер-линтера) с путём и позицией байта; остальные файлы проверяются, rc=1.
- **Два ужесточения** (ADR-0026 Решение 8): самозакрытый открывающий `<comment id="…"/>` без парного `</comment>` — ERROR `unpaired <comment>` (прежде тишина); тег, разорванный переносом строки, — ERROR «тег разорван» (прежде считался позицией комментария).
- **Подпапка без `_index.md`**: с `optionalCategoryIndex: true` ошибки нет; без флага ERROR остаётся с новым текстом — «раздела в дереве нет, статьи подняты выше».
- **JSON-контракты напрямую**: `gramax-tags.json` — `schemaVersion` 3, `gramax-catalog-rules.json` — `schemaVersion` 2; новый файл данных `gramax-lucide-icons.json` (`schemaVersion` 1).
- **Живой замер рендер-проб** (ADR-0027): зовётся явно — `bash scripts/render-quality/live.sh`; полная недоступность цели — именованный отказ `RENDER_TARGET_UNREACHABLE` rc=2 без отчёта (прежде rc=1 с отчётом); сетевой отказ uv — `PLAYWRIGHT_PIN_UNRESOLVED` rc=2 с рычагом `UV_OFFLINE=1`; `--full` длиннее на четыре шага и около 16 с.

## Summary

| Метрика | Значение |
|---|---|
| Вердикт gate | **pass** — 23/23 AC: 23 PASS / 0 N/A / 0 FAIL |
| Полный гейт (координатор, qa-057) | прогон 1 (`7d8001c`) rc=1 — два тестовых отказа (`ac-134`, `ac-105`); прогон 2 (`07c05c0`) rc=0, `RESULT: PASS` — все 21 шаг `--full` зелёные (217 AC-ног по 17 сюитам), хвостовой `--fast` PASS; `diff` логов — 38 строк, все в блоках двух исправленных стабов |
| Прогоны BA (2026-11-23, моя рука) | 33 стаба rc=0: comments 5, catalog-validator 11 (включая перевод `ac-030`), render-linter 4, plugin-contract 1 (`ac-140`), gate-composition 7, render-quality 4 (`ac-141`, `ac-142`, переводы `ac-105`, `ac-118`), writer-sync-470 1 (`ac-086`); pytest — 25 passed (`test_validate_structure.py` 16, `test_validators_parity.py` 4, `test_validate_render.py` 5) |
| Валидаторы на `docs/` (моя рука) | `python3 -B plugins/gramax/scripts/validate_structure.py docs` — rc=0, вывод пуст (0 ERROR, 0 WARNING); `python3 -B plugins/gramax/scripts/validate_comments.py docs` — rc=0, вывод пуст; `python3 -B plugins/gramax/scripts/validate_render.py docs` — rc=0, `Итого: файлов=129, ERROR=0` |
| NFR-084 / NFR-085 | NFR-084 — все касания тестов закрытых эпиков суть переводы на новую семантику, ни один ассерт не удалён и не обезврежен (раздел «Гейты приёмки»); NFR-085 — `--full` зелёный без сети, проб и токена (прогон 2), живой замер — именованный шаг вне гейта |
| Красные линии | секретов и PII нет; имя живого каталога и хостов в документе не названы — только «корпус сравнения»; `tests/` тронуты только переводами NFR-084 и рождениями стабов at-design |

## AC coverage (AC-129…AC-151)

| AC | Тест (файл) | Реализация (файл) | Результат | Вердикт |
|---|---|---|---|---|
| AC-129 (FR-210) | `tests/gramax/comments/ac-129-multiposition-id.sh` — rc=0 (моя рука); корпус: «duplicate comment id» 16 → 0, 16 информационных строк (замер координатора) | `plugins/gramax/scripts/validate_comments.py`; `plugins/gramax/skills/comments-write/SKILL.md`, `plugins/gramax/skills/comments-read/SKILL.md` | повторный ID — не ошибка, ID показан с позициями; `--delete` описан как снятие всех позиций; формат-ID проверка сохранена | **pass** |
| AC-130 (FR-211) | `tests/gramax/comments/ac-130-xml-block-form.sh` — rc=0 (моя рука) | `plugins/gramax/scripts/parse_comments.py`, `validate_comments.py`; оба навыка `SKILL.md` | XML-форма распознана parse и validate, якорь выводится, «md missing tag for yaml id» нет; XML-форма названа каноном для `syntax: XML`; скобочная legacy читается | **pass** |
| AC-131 (FR-211) | `tests/gramax/catalog-validator/ac-131-xml-comment-unpaired.sh` — rc=0 (моя рука); корпус: ложных `unpaired <html>` — 0 (замер координатора) | `plugins/gramax/scripts/validate_structure.py` | «unpaired» на XML-форме нет; скобочная форма парна как прежде; оборванный блок — одна находка (негатив-нога жива) | **pass** |
| AC-132 (FR-212) | `tests/gramax/render-linter/ac-132-broken-utf8-render.sh`, `tests/gramax/comments/ac-132-comments-utf8-skip.sh` — оба rc=0 (моя рука) | `plugins/gramax/scripts/lib/read_page.py` + `validate_render.py`; `validate_comments.py`, `parse_comments.py` | `FAIL <путь>` + `ERROR L0` с байтом `0xd0` и позицией/размером из фикстуры, без traceback; обход полный, rc=1; валидатор комментариев — E036, читатель пропускает с предупреждением на stderr, rc=0 | **pass** |
| AC-133 (FR-212) | `tests/gramax/catalog-validator/ac-133-broken-utf8-traversal.sh` — rc=0 (моя рука) | `plugins/gramax/scripts/lib/read_page.py` + `validate_structure.py` | ровно одна E036 («байт `0xd0` на позиции 127 из 129» — из байтов фикстуры), без traceback; находка bait-файла `unpaired <html>` доказывает обход до конца; rc=1; фикстуры в render-linter и catalog-validator, сюиты зелёные | **pass** |
| AC-134 (FR-213) | `tests/gramax/catalog-validator/ac-134-language-optional.sh` — rc=0 (моя рука, после ремонта хелпера в `07c05c0`); корпус: 1 → 0 (замер координатора) | `plugins/gramax/gramax-catalog-rules.json` (`docRootOptionalFields`), `validate_structure.py`; `plugins/gramax/README.md`, `plugins/gramax/skills/writer/references/doc-root-schema.md` | без `language` — 0 ERROR; типо-проверка присутствующего (число/null/пустая строка — ошибка) жива; README, контракт и CHANGELOG говорят одно (`schemaVersion` 2) | **pass** |
| AC-135 (FR-214) | `tests/gramax/catalog-validator/ac-135-table-tags-contract.sh`, `tests/gramax/render-linter/ac-135-table-balance-single-finding.sh` — оба rc=0 (моя рука); корпус: W034 1072 → 11, табличного класса нет — 999 → 0 (замер координатора) | `plugins/gramax/gramax-tags.json` (`schemaVersion` 3, `pairedTags` +`table`/`tr`/`td`), `validate_structure.py`; баланс — только `validate_render.py` | теги таблицы известны; баланс не дублируется — одна находка от render-линтера (BR-027, варден); незнакомый `<mywidget>` по-прежнему W034; строка `Contract:` в CHANGELOG (раздел 4.10.0) | **pass** |
| AC-136 (FR-215) | `tests/gramax/catalog-validator/ac-136-lucide-registry-boundary.sh`, перевод `ac-030-icon-lucide-boundary.sh` — rc=0 (моя рука); pytest `test_validators_parity.py` — 4 passed (моя рука); корпус: W035 90 → 0 (замер координатора) | `plugins/gramax/gramax-lucide-icons.json` (новый, `schemaVersion` 1), `validate_structure.py` | голые коды `check`/`ban`/`aperture`/`info` и `CHECK` (по `code.lower()`) молчат; `lucide-zap` — W035 с подсказкой убрать префикс; `my-custom-x`/`xlucide-zap` — W035 как пользовательские; файл в `.icons/` приоритетнее реестра | **pass** |
| AC-137 (FR-216) | `tests/gramax/catalog-validator/ac-137-html-block-mask.sh`, `tests/gramax/render-linter/ac-137-html-block-render.sh`, регрессионные `ac-137b-html-nested-blocks.sh`, `ac-137b-html-nested-render.sh` — все rc=0 (моя рука); корпус: ложных находок класса html-блоков нет (замер координатора) | `plugins/gramax/scripts/lib/md_code_mask.py` (`_mask_html_blocks`), `validate_structure.py`, `validate_render.py` | теги и W035-код внутри `<html>`-блока молчат; `<html>` в inline-коде и fenced-блоке маску не переключает (дефекты после упоминаний ловятся); внешняя пара балансируется; вложенность любой глубины — точный баланс (регрессия закрыта в `7d8001c`) | **pass** |
| AC-138 (FR-217) | `tests/gramax/catalog-validator/ac-138-optional-category-index.sh` — rc=0 (моя рука) | `gramax-catalog-rules.json` (`indexPolicy.subfolderOptionalFlag`), `validate_structure.py`; `doc-root-schema.md` | `optionalCategoryIndex: true` снимает ERROR; `"true"` строкой и `false` — не снимают; без флага ERROR с дословной формулировкой «раздела в дереве нет, статьи подняты выше»; флаг объявлен в контракте | **pass** |
| AC-139 (FR-218) | `tests/gramax/comments/ac-139-reply-user-id.sh` — rc=0 (моя рука); корпус: 5 истинных предупреждений «у ответа нет `user.id`» (замер координатора) | `plugins/gramax/skills/comments-write/SKILL.md` (шаблон ответа: `id` равен `mail`), `validate_comments.py` | ответ без `user.id` даёт warning (rc=0); обе формы пустых `answers` (`answers: []` и без ключа) проходят без предупреждений; «duplicate answer» ловится | **pass** |
| AC-140 (FR-221a) | `tests/gramax/plugin-contract/ac-140-readme-version-docstring.sh` — rc=0 (моя рука) | `plugins/gramax/README.md`, `plugins/gramax/.claude-plugin/plugin.json` — 4.10.0; докстринг `validate_render.py` | версия README равна `plugin.json` (нога краснеет при расхождении — проверено подкладыванием на 4.9.0 в at-design); докстринг согласован с `gramax-render-rules.json`: `th` — WARN, запасной ERROR-текст не подаётся как действующий (варден-нога) | **pass** |
| AC-141 (FR-219) | `tests/gramax/render-quality/ac-141-no-live-leg.sh` — rc=0 (моя рука); зелёный `--full` — прогон координатора (BA агрегаторы не исполняет): `/tmp/gramax-full-2.txt` — rc=0, `RESULT: PASS`, 21 шаг | `scripts/check-gramax.sh`, `tests/gramax/render-quality/run.sh` | исполняемых строк с `probe.sh`/`live.sh` в гейте нет; `--full` зелёный на чистом дереве без сети, проб и токена (HEAD `07c05c0`); стационарное состояние D5 достигнуто | **pass** |
| AC-142 (FR-219) | `tests/gramax/render-quality/ac-142-named-refusals.sh` — rc=0 (моя рука, поведенческий офлайн: цель на закрытом порту, фейковый uv с сигнатурой «Failed to fetch») | `scripts/render-quality/live.sh` (обёртка `probe.sh`), `uv_named_refusal` в `probe.sh`, `RENDER_TARGET_UNREACHABLE` в `probe.py`; `docs/70-operations/2026-11-21-render-quality-runbook.md`, `tests/gramax/render-quality/README.md` | недостижимая цель — rc=2, баннер `REFUSAL RENDER_TARGET_UNREACHABLE:` с подсказкой и `live.sh`; сетевой отказ uv — rc=2, `REFUSAL PLAYWRIGHT_PIN_UNRESOLVED:` с рычагом `UV_OFFLINE=1` и `warm.sh`; runbook и README называют шаг и рычаг; D8 волны-2 перефиксировано (D5 дерева волны-3); сама сессия замера — вне гейта, не исполнена (см. «Действия вне гейта») | **pass** |
| AC-143 (FR-220a) | `tests/gramax/gate-composition/ac-143-suite-statuses.sh` — rc=0 (моя рука); `cross-catalog-retraction` 9/9 в прогоне 2 (лог 2: 735–754) | `scripts/check-gramax.sh`; `tests/gramax/archive/docs-migration/` + `tests/gramax/archive/README.md`; `tests/gramax/cross-catalog-retraction/` (`README.md`, `run.sh`) | cross-catalog-retraction подключена к `--full` (шаг 20 + строка заголовка); docs-migration в `archive/` без правки байтов, со строкой-свидетельством; gate-composition — последний шаг 21; `--full` зелёный | **pass** |
| AC-144 (FR-220b) | `tests/gramax/gate-composition/ac-144-dogfood-validators.sh` — rc=0 (моя рука); мои прогоны обоих валидаторов на `docs/` — rc=0, вывод пуст | `scripts/check-gramax.sh` (шаги `validate-structure`, `validate-comments` без хвостов-подавления rc), оба валидатора | 0 ERROR на `docs/` в прогоне 2 (лог 2: 389–392) и в моих прогонах; предупреждения закрыты: 3 W034-плейсхолдера — правкой строк (AC-148), 4 ложных «invalid comment id format» — маской кода (ADR-0026 Решение 8); `--fast`-путь шагов не менялся | **pass** |
| AC-145 (FR-220c) | `tests/gramax/gate-composition/ac-145-overlay-sunset.sh` — rc=0 (моя рука); `orphan-references` PASS в прогоне 2 (лог 2: 397–399) | пять файлов удалены из `scripts/` (`ls` — отсутствуют); `tests/gramax/orphan-references/sunset-registry.txt` (пять якорей дословно); пометка в `docs/60-implementation/test-reports/2026-11-19-night-review-report.md:55` | `scripts/apply-overlay.sh` и четыре хелпера удалены, записи реестра — путь или вызов; запись ночного отчёта помечена 2026-11-23 (ADR-0027 Решение 6) | **pass** |
| AC-146 (FR-221b) | `tests/gramax/gate-composition/ac-146-root-texts.sh` — rc=0 (моя рука) | `CLAUDE.md`, корневой `README.md` | состав 7 навыков и агент назван, литерала `v0.3.1` нет; `--full` описан как 2 валидатора + 17 сюит; порог C14 цел; якоря предусловий ADR-0008/RES-001 и предупреждение о конфликте триггеров `gramax:mermaid` в README; `--fast` PASS (хвост прогона 2; повтор после посадки — ниже) | **pass** |
| AC-147 (FR-221c) | `tests/gramax/gate-composition/ac-147-texts-and-header.sh` — rc=0 (моя рука); мой греп заголовка `scripts/check-gramax.sh` — «17 сюит» | заголовок `scripts/check-gramax.sh`; `tests/gramax/render-quality/README.md`, `tests/gramax/plantuml-bpmn/README.md` | множества сюит заголовка и исполняемых строк тела `--full` равны; README render-quality без «не подключён ни к одному гейту», README plantuml-bpmn актуален; варден `ac-118` зелёный — изоляция `--fast` сохранена | **pass** |
| AC-148 (FR-216) | `tests/gramax/catalog-validator/ac-148-docs-w034-zero.sh` — rc=0 (моя рука) + мой прогон `validate_structure.py docs` — вывод пуст | три строки `docs/`: `docs/00-project/adr/0021-docs-layout-inversion.md`, `docs/30-requirements/2026-11-18-plantuml-bpmn-requirement.md`, `docs/60-implementation/2026-08-13-doc-root-discovery-dev-notes.md` | плейсхолдеры `<home>`, `<file>`, `<raw>` устранены (формулировка/code-span); 0 W034 на `docs/` — подтверждено двумя независимыми прогонами (стаб и моя рука) | **pass** |
| AC-149 (FR-221г) | `tests/gramax/gate-composition/ac-149-changelog-calibration.sh` — rc=0 (моя рука) | `plugins/gramax/CHANGELOG.md` (запись 4.9.0), `docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md` | запись калибровки волны-1: note-in-cell и note-in-note → WARN, colgroup-multiline → ERROR (в одном окне); маркер «Опоры» в шапке записи (первые 30 строк, до первого `## `); `SIGNAL` по файлу нет | **pass** |
| AC-150 (FR-221д) | `tests/gramax/gate-composition/ac-150-identifier-registry.sh` — rc=0 (моя рука); мои грепы: `AC-152`…`AC-163` в требовании паритета, жирных `AC-061`/`AC-062` там нет | `docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md`, `docs/30-requirements/2026-11-23-identifier-ranges-registry.md`, `tests/gramax/catalog-validator/README.md` | каждый AC глобальной эры определён ровно один раз (варден-скан требований); диапазон паритета перенумерован на `AC-152`…`AC-163`, карта README обновлена, имена стабов `ac-025`…`ac-036` не менялись; реестр диапазонов заведён и называет владельца каждого диапазона (дефект перенумерации пойман ревью — см. «Находки») | **pass** |
| AC-151 (FR-209) | `tests/gramax/catalog-validator/ac-151-index-properties-verdict.sh` — rc=0 (моя рука); pytest `IndexPropertiesVerdictTests` в `test_validate_structure.py` — 16 passed (моя рука); корпус: 43 → 0 (замер координатора) | `validate_structure.py`, `gramax-catalog-rules.json`, `plugins/gramax/skills/writer/SKILL.md` | вердикт равен ADR-0026 Решению 5 (ключ штатный и видимый; ERROR снят, WARN не введён); V3–V5 применяются к индексам подпапок (объявленное свойство чисто, необъявленное/вне enum/плоская нотация — находки), индекс корня вне проверок; writer и валидатор говорят одно | **pass** |

## Гейты приёмки

| Гейт | Результат |
|---|---|
| Backlog-closure | `✓ n/a` — `scripts/check-backlog-closure.py` в дереве отсутствует |
| Breaking-change-guide | `✓ n/a` — `scripts/check-breaking-change-section.py` в дереве отсутствует; содержание нормы несёт внесекционный раздел «Breaking change» выше (видимое потребителю поведение + блок Breaking change раздела 4.10.0 в CHANGELOG + миграционный смысл) |
| Downstream-test-touch (advisory, ADR-028 D3) | **pass** — разбор ниже |

**Downstream-test-touch:** окно касается тестов закрытых эпиков в четырёх местах, все — переводы на новую семантику под NFR-084, ни один ассерт не удалён и не обезврежен:

- `tests/gramax/writer-sync-470/ac-086-fragment-canonical-legacy.sh` (закрытый эпик writer-sync): пин `schemaVersion` `gramax-tags.json` 2 → 3 — перевод под ADR-0026 Решение 2, ассерт продолжает пинить версию контракта; rc=0 моей рукой. Сила сохранена.
- `tests/gramax/catalog-validator/`: имена стабов `ac-025`…`ac-036` не менялись (стабильность ссылок), метки переведены на `AC-152`…`AC-163`; `ac-030-icon-lucide-boundary.sh` переведён на семантику реестра иконок (голый `zap` молчит, `lucide-zap` — W035 с подсказкой) — rc=0 моей рукой. Вардены ac-026/ac-029 и негативы не тронуты; сюита 46/46 в прогоне 2.
- `tests/gramax/render-quality/ac-105-config-no-hardcode.sh` (закрытая волна-1 прибора): перевод под ADR-0027 Решение 2 — rc=2, баннер именованного отказа, «отчёт не пишется», цель из конфига по-прежнему называется; сила ноги сохранена и усилена новой ногой. `ac-118-fast-isolation.sh`: перевод вардена на исполнимые строки — запрет живой ноги в `--fast` сохранён целиком. Оба rc=0 моей рукой.
- pytest `plugins/gramax/scripts/tests/`: `test_validators_parity.py` (`XlucidePrefixBoundaryTests` — граница префикса), `test_validate_structure.py` (`test_v2_index_with_properties` заменён классом `IndexPropertiesVerdictTests`, фикстура перенесена в `good/`, смок «exit 0 и пустой stdout» не ослаблялся) — 4 и 16 passed моей рукой.

Необходимость каждого касания — смена контракта решением (BR-025: ассерты, проверяющие контракт, обязаны следовать записи в том же цикле); сохранение силы — ассерты продолжают проверять факт (версия, код отказа, граница, вердикт), подтверждено прогонами выше и 217/217 зелёных ног гейта.

## Замер координатора на корпусе сравнения

Живой каталог, 766 страниц, `syntax: XML`; валидаторы 4.9.0 → рабочее дерево 4.10.0. Источник — после-замер координатора; корпус приватный, в гейте цифр нет (qa-057, «После-замер»).

| Валидатор | 4.9.0 | 4.10.0 (рабочее дерево) | Комментарий |
|---|---|---|---|
| `validate_structure` | ERROR 140, WARNING 1648 (W034 1072, W035 90) | ERROR 96, WARNING 539 (W034 11, W035 0) | снятые классы: 43 «properties в `_index.md`», 1 «missing field: language»; ложных `unpaired <html>` — 0 (регрессия вложенных html-блоков поймана этим замером и закрыта в `7d8001c`); остаток W034 (11) — реальные находки |
| `validate_comments` | ERROR 160 («duplicate comment id» 16) | ERROR 144 («duplicate comment id» 0) | 16 информационных строк о много-позиционных ID (AC-129); 5 истинных предупреждений «у ответа нет `user.id`» (AC-139); «md missing tag for yaml id» 122 → 122 — реальная рассинхронизация md↔yaml: блоковых комментариев в XML-форме корпус не несёт, класс правится вне волны |
| `validate_render` | ERROR=5 | ERROR=5 | все пять — реальные киллеры; traceback нет (AC-132/AC-133) |

Ограничение корпуса: ни одного файла с битым UTF-8 и ни одного блочного комментария в XML-форме в корпусе нет — классы AC-132/AC-133 (UTF-8) и AC-130/AC-131 (XML-форма) корпусом не представимы и доказаны фикстурами сюит (`comments`, `catalog-validator`, `render-linter`); числа в строках выше им не противоречат.

## Находки и отклонения (все именованы, ни одна не блокирует)

| # | Находка | Классификация | Закрытие |
|---|---|---|---|
| 1 | Ремонты четырёх стабов QA-author после цикла Dev (согласовано с PM, таблица в at-design): `import sys` в однострочниках `ac-134`/`ac-135`/`ac-136`; нога (f) `ac-151` — против формулировки V2, не слова «properties»; фикстура `comments/ac-132` — добавлена вторая здоровая пара; bait-нога `ac-133` — непарный `<html>` вместо `<note>` (BR-027). Контракт ни одного стаба не ослаблен | дефекты самих заглушек | исполнены до зелёного состояния; ассерты не менялись |
| 2 | Регрессия вложенных html-блоков: маска глотала внутренний `<html …>` — ложные `unpaired <html>` и ложный баланс в хвосте обёртки. Ни одной сюитой гейта не ловилась — поймана после-замером координатора на корпусе сравнения до релиза | продукт, найдена процессным шагом | фикс `7d8001c` (`_mask_html_blocks` — счётчик глубины), стабы `ac-137b` в двух сюитах (обе rc=0 моей рукой); рекомендация qa-057 — держать замер корпуса обязательным шагом ритуала |
| 3 | Дефект перенумерации: регулярка с арифметикой дала вид `AC-15-NN`/`AC-16-NN` в пяти файлах — пойман независимым ревью, не сюитой | продукт/тексты | исправлено на `AC-152`…`AC-163`; варден `ac-150` усилен (12 определений в требовании паритета, запрет идентификаторов с лишним дефисом, проверено подкладыванием); урок в `docs/lessons-learned.md` (2026-11-23: перенумерация — таблицей соответствия, не регуляркой) |
| 4 | Первый полный прогон (`7d8001c`) красный по двум тестовым ногам: `ac-134` — хелпер возвращал код `rm -rf` вместо кода валидатора (сам валидатор вёл себя верно); `ac-105` — стаб пиннил заменённый контракт волны-1 (rc=1 с отчётом) вместо ADR-0027 Решение 2 (rc=2 без отчёта) | test-adaptation, оба | коммит `07c05c0`; перепроверены зелёными в прогоне 2 (46/46 и 20/20); сопутствующая правка продукта — баннер отказа в `probe.py` называет `baseUrl` из конфига |
| 5 | Две строки `DRIFT_CHECK pairedTags/selfClosingTags: N/A` в catalog-validator — литералы `PAIRED_TAGS`/`SELF_CLOSING` в коде не найдены: целевое состояние ADR-0012 Решение 3 (код читает JSON), сравнивать не с чем | информационное | действий нет (qa-057) |

## Действия вне гейта

- **Сессия замера на портале** — beads `gramax-o0q.3`: нужен токен и санкция владельца на публикацию проб. В этой волне не исполнена — релизная заметка 4.10.0 фиксирует «шаг замера — не исполнен» (ADR-0027 Решение 1); одиночная проба координатора по неопубликованной цели дала 21/21 `NOT_FOUND` — ожидаемое состояние до публикации.
- **GES-окно** — beads `gramax-o0q.4` (владелец и агент, внешнее окно).
- **Малые остатки** — beads `gramax-o0q.46`, `gramax-4jf.14` (хвосты вне скоупа волны, свои триггеры).

## Постпроверка

```text
# стабы волны-3 — rc=0 (прогоны BA 2026-11-23; для render-quality с UV_OFFLINE=1):
$ for s in <33 стаба из таблицы AC coverage>; do bash tests/gramax/<suite>/$s.sh; done   # все RC=0
$ cd plugins/gramax/scripts && UV_OFFLINE=1 uv run --quiet --with pytest python -m pytest -q tests/
# 16+4+5 passed (test_validate_structure.py, test_validators_parity.py, test_validate_render.py)
$ python3 -B plugins/gramax/scripts/validate_structure.py docs; echo RC=$?   # вывод пуст, RC=0
$ python3 -B plugins/gramax/scripts/validate_comments.py docs; echo RC=$?    # вывод пуст, RC=0
$ python3 -B plugins/gramax/scripts/validate_render.py docs                  # Итого: файлов=129, ERROR=0, RC=0
$ bash scripts/check.sh --fast 2>&1 | tail -8                                # см. VERDICT
```

---

## VERDICT

**pass: 23/23 AC покрыты — 23 PASS / 0 N/A / 0 FAIL.**

Волна-3 принята в составе: пять контрактов валидаторов откалиброваны дословно по движку `48592b36` (ADR-0026) — `language` вне обязательных полей, `table`/`tr`/`td` в `pairedTags` с `schemaVersion` 3, реестр кодов Lucide, `optionalCategoryIndex` через `indexPolicy.subfolderOptionalFlag`, запрет `properties` в `_index.md` снят с переносом V3–V5 на индексы подпапок (AC-129…AC-139, AC-151); контур комментариев распознаёт обе блочные формы, маскирует код и не падает на битом UTF-8 (AC-129…AC-133, AC-139); контракты синхронны в триаде «валидатор — README — навык» со строками `Contract:` в CHANGELOG и версией 4.10.0 (AC-134…AC-140); гейт `--full` зелёный в стационарном состоянии — живая нога выведена в именованный шаг `bash scripts/render-quality/live.sh` с именованными отказами rc=2 и рычагом `UV_OFFLINE=1` (AC-141, AC-142, NFR-085); обе бесстатусные сюиты получили явный статус, свои валидаторы догфудят `docs/` с порогом 0 ERROR, мёртвый overlay-тулинг удалён с записью (AC-143…AC-145); тексты репозитория, запись калибровки волны-1, реестр диапазонов идентификаторов и перенумерация паритета на `AC-152`…`AC-163` исполнены (AC-146…AC-150). Сюиты силу сохранили (NFR-084 — все касания суть переводы), оба отказа первого прогона — тестовые и закрыты, регрессия вложенных html-блоков поймана замером корпуса до релиза и закрыта со стабами. Гейты приёмки: Backlog-closure `✓ n/a`, Breaking-change-guide `✓ n/a`, Downstream-test-touch — pass.

**Передача:** PM — релизный коммит 4.10.0 (четыре текста релиза ждут в рабочем дереве) и финальный полный гейт после посадки этого документа; сессия замера, GES-окно и малые остатки — beads вне гейта (выше). Код, тесты и фикстуры этой приёмкой не менялись; артефакты сессии — этот документ и его индексная строка.
