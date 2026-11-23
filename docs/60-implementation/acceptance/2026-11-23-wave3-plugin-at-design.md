---
title: "AT-design: Волна-3 — контракты валидаторов и навыков комментариев: стабы comments, catalog-validator, render-linter, plugin-contract и переводы ассертов (AC-129…AC-140, AC-148, AC-151)"
order: 21
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

# AT-design: Волна-3 — контракты валидаторов и навыков комментариев: стабы comments, catalog-validator, render-linter, plugin-contract и переводы ассертов (AC-129…AC-140, AC-148, AC-151)

**Роль:** QA-author (тест-дизайн и born-red стабы до реализации Dev; TDD-цепочка
qa-author → dev → qa-runner, BR-025).
**Требование:** [Волна-3 — релиз 4.10.0](../../30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md)
(AC-129…AC-140, AC-148, AC-151; NFR-084; BR-025…BR-027).
**Решение:** [ADR-0026](../../00-project/adr/0026-validator-contracts-engine-pin.md) — семь
решений и дословные целевые значения; **Дизайн:**
[2026-11-23-wave3-validator-contracts-design](../../40-architecture/2026-11-23-wave3-validator-contracts-design.md)
(§2.4 — сообщения дословно, §2.5 — правки скриптов, §6 — контракт с QA-author: сценарии,
границы для AC-129…131/137/139/140, граничные случаи, пирамида). Формат — по модели
[at-design волны-2 render-quality](2026-11-21-render-quality-wave2-at-design.md).
**Бэклог:** beads `gramax-4jf.2…4jf.13` (симптомы и evidence `file:line`); числа корпуса
сравнения (999, 90, 43, 16) — замеры приёмки координатора, стабами не читаются: приватный
корпус вне входов, фикстуры — собственный текст.
**Артефакты этой задачи:** новый suite `tests/gramax/comments/` (5 стабов, фикстуры, run.sh,
README); новые стабы и фикстуры в `tests/gramax/catalog-validator/` (9), `tests/gramax/render-linter/`
(3), `tests/gramax/plugin-contract/` (1); переводы цвето-меняющих ассертов
(`writer-sync-470/ac-086…`, `catalog-validator/ac-030…`, `test_validators_parity.py`,
`test_validate_structure.py` с переносом фикстуры в `good/`); этот at-design. Индексную строку
заводит PM.

## Уровни (пирамида — по рекомендации дизайна §6)

- **unit** — разбор фикстур без окружения: комментарии (AC-129, AC-130, AC-139), маска и
  членство реестра (часть ног ac-136), граница префикса в `test_validators_parity.py`.
- **integration** — CLI валидатора на фикстурном каталоге, rc и текст вывода: AC-131, AC-132,
  AC-133, AC-134, AC-135, AC-136 (CLI), AC-137, AC-138, AC-151; граница UTF-8 в pytest.
- **integration (static)** — тексты манифестов и README в дереве: AC-140; тексты навыков —
  ноги ac-130/ac-139.

## Покрытие AC

Каждый AC карты покрытия — хотя бы один стаб с AC-номером в имени. Формат «Уровень» —
по пирамиде выше. Красная причина каждой строки — «почему красный на 7553da1», замер
2026-11-23 на HEAD 7553da1.

| Стаб | AC | Уровень | Ожидаемый цвет на 7553da1 и почему |
|---|---|---|---|
| `comments/ac-129-multiposition-id.sh` | AC-129 (FR-210) | integration | 🔴 `validate_comments.py:61-67` ставит ERROR «duplicate comment id in md: abcde (appears 2 times)», rc=1; ожидание: rc=0, «duplicate» нет, ID показан (info, `--strict` не эскалирует); негатив-нога: «invalid comment id format» остаётся (замер: да) |
| `comments/ac-130-xml-block-form.sh` | AC-130 (FR-211) | integration + static | 🔴 `INLINE_RE`/`BLOCK_RE` требуют «>» сразу после id — XML-форма не матчится: parse_comments даёт `anchor_not_found`, validate_comments — «md missing tag for yaml id», rc=1; навыки знают только скобочную форму (gramax-4jf.4). Ноги-контроли зелёные: скобочная legacy читается и после |
| `catalog-validator/ac-131-xml-comment-unpaired.sh` | AC-131 (FR-211) | integration | 🔴 `check_tags` (`validate_structure.py:391`) не считает самозакрытый тег открывающим — «unpaired `<comment>`: 0 open, 1 close» на фикстуре; нога скобочной формы зелёная |
| `render-linter/ac-132-broken-utf8-render.sh` | AC-132 (FR-212) | integration | 🔴 `read_text` в `check()` (`validate_render.py:75`) роняет UnicodeDecodeError traceback'ом, обход обрывается; ожидание: `FAIL <путь>` + дословная «ERROR L0: …» с байтом 0xd0 и позицией/размером, вычисленными по байтам фикстуры; ERROR bait-файла и OK чистого присутствуют, rc=1 |
| `comments/ac-132-comments-utf8-skip.sh` | AC-133 в части комментариев (FR-212 — «проверяется то же») | integration | 🔴 traceback на битый `.md`; ожидание: E036 по одной на битый `.md` и битый `.comments.yaml` (BR-004), путь и байт названы; parse_comments — предупреждение на stderr с путём, rc=0, отчёт по здоровому файлу полон |
| `catalog-validator/ac-133-broken-utf8-traversal.sh` | AC-133 (FR-212) | integration | 🔴 UnicodeDecodeError на первом же чтении; ожидание: rc=1, traceback нет, ровно одна E036 («байт 0xd0 на позиции P из S», P/S из фикстуры), находка bait-файла «unpaired `<note>`» доказывает обход до конца |
| `catalog-validator/ac-134-language-optional.sh` | AC-134 (FR-213) | integration | 🔴 «missing field: language» на каталоге без language (rc=1); ожидание: rc=0, типо-проверка присутствующего остаётся (123/null/пустая строка — «invalid type», ноги зелёные сегодня), контракт: schemaVersion 2, `docRootOptionalFields` с language |
| `catalog-validator/ac-135-table-tags-contract.sh` | AC-135 (FR-214) | integration | 🔴 W034 на table/tr/td каждой XML-таблицы (3 находки на фикстуре); schemaVersion 2, тегов в `pairedTags` нет; ноги-контроли зелёные: баланс не дублируется структурным валидатором (BR-027), genuinely неизвестный `<mywidget>` — W034 остаётся, th вне `pairedTags` |
| `render-linter/ac-135-table-balance-single-finding.sh` | AC-135 — рендер-сторона (FR-214, BR-027) | integration | 🟢 ЗЕЛЁНЫЙ С РОЖДЕНИЯ — **warden**: одна баланс-находка от validate_render уже сегодня, дубля от validate_structure нет; сторожит, чтобы расширение `pairedTags` (Решение 2) не задвоило находку и не убило баланс; обоснование — как у warden-ног ac-026/ac-029: проверяемое поведение обязано пережить правку контракта |
| `catalog-validator/ac-136-lucide-registry-boundary.sh` | AC-136 (FR-215) | integration (unit-ноги контракта) | 🔴 реестра `gramax-lucide-icons.json` нет; голые check/ban/aperture/info и CHECK дают W035; `lucide-zap` молчит (ожидание: W035 с подсказкой «уберите префикс»); ноги-контроли зелёные: my-custom-x и xlucide-zap — W035, `zap-with-file` — находки нет (файл приоритетнее) |
| `catalog-validator/ac-137-html-block-mask.sh` | AC-137 (FR-216) | integration | 🔴 title/div/br и W035 внутри `<html>`-блока дают W034/W035 (4 находки); ожидание: молчат; ноги-контроли зелёные: `<mytag>` вне блока ловится, упоминание `<html>` в inline-коде и fenced-блоке маску не переключает (два дефекта после упоминаний ловятся), непарный внешний `<html>` балансируется как прежде |
| `render-linter/ac-137-html-block-render.sh` | AC-137 (FR-216) | integration | 🔴 инлайновый `<note>` и незакрытый `<td>` внутри блока дают ERROR rc=1; ожидание: rc=0; нога-варден зелёная: `<html>` в коде не переключает маску — настоящий `<th>` после упоминаний даёт баланс-ERROR (замер: да) |
| `catalog-validator/ac-138-optional-category-index.sh` | AC-138 (FR-217) | integration | 🔴 флаг не читается: все четыре варианта `.doc-root.yaml` дают ERROR со старой формулировкой «Gramax не покажет раздел в навигации»; ожидание: `optionalCategoryIndex: true` снимает (rc=0), строка `"true"`/`false`/без флага — ERROR с дословной формулировкой §2.4; контракт: `indexPolicy.subfolderOptionalFlag` |
| `comments/ac-139-reply-user-id.sh` | AC-139 (FR-218) | integration + static | 🔴 ответ без user.id — тишина (ожидание: warning с упоминанием user.id, rc=0); шаблон «Операция 2: Ответить» в comments-write не несёт id под user; ноги-контроли зелёные: обе формы пустых answers проходят, «duplicate answer» ловится |
| `plugin-contract/ac-140-readme-version-docstring.sh` | AC-140 (FR-221a) | integration (static) | 🔴 README называет 4.8.0, plugin.json — 4.9.0; первый докстринг-сентенс `validate_render.py` несёт `<th>` в перечислении «роняют рендерер GES (HTTP 500)» при контракте th severity warn, th+WARN в докстринге нет; нога-варден зелёная: запасной ERROR-текст не звучит в README/докстринге |
| `comments/ac-144-comments-illustrations-not-markup.sh` | FR-216 → порог AC-144 (comments-нога; см. «Отклонения») | integration | 🔴 DOTALL-мост `INLINE_RE` + отсутствие маски кода: иллюстрации в inline-коде и fenced-блоке дают ложные «yaml missing key for md id», rc=1 (gramax-4jf.13); разорванный переносом тег даёт ложный ID вместо находки «тег разорван» |
| `catalog-validator/ac-148-docs-w034-zero.sh` | AC-148 (FR-216) | integration (dogfood) | 🔴 прогон по `docs/` даёт 3 W034 — плейсхолдеры `<home>` (0021-docs-layout-inversion.md:389), `<file>` (plantuml-bpmn-requirement.md:191), `<raw>` (doc-root-discovery-dev-notes.md:42); пути совпадают с §6 дизайна; владельцем правки docs/ — Dev |
| `catalog-validator/ac-151-index-properties-verdict.sh` | AC-151 (FR-209) | integration | 🔴 V2 «не должен содержать properties» на всех пяти индексах фикстуры, V3–V5 на них заглушены условием `md_file.name != "_index.md"`; ожидание: V2 снят целиком, индекс корня вне находок, индекс подпапки с объявленным свойством чист, V4/V3/V5 на индексах подпапок работают |
| pytest `test_validate_structure.py` → `IndexPropertiesVerdictTests` | AC-151 (FR-209) | integration | 🔴 те же ноги уровнем pytest (перевод `test_v2_index_with_properties`); фикстура общая со стабом ac-151 |
| pytest `test_validators_parity.py` → `XlucidePrefixBoundaryTests` | AC-136 (FR-215, перевод AC-157) | unit | 🔴 `lucide-zap` сегодня не упоминается (старый ассерт «нет упоминаний»); перевод: упоминается с W035 и подсказкой «префикс»; `xlucide-zap` остаётся пользовательским |

**Итог:** 17 стабов-файлов (5 comments + 9 catalog-validator + 3 render-linter + 1 plugin-contract,
считая перевод ac-030) + 2 переведённых pytest-теста; 14 красных на assert, 3 зелёных
(`ac-135-table-balance-single-finding`, нога-варден внутри ac-137/ac-140 и контроли внутри
многоногих стабов — каждая зелёная нога названа в таблице).

## Границы и негативы (сверх счастливого пути)

- **Маскированный отказ** — у каждого стаба есть нога «проверка остаётся»: формат ID
  (ac-129), скобочная форма (ac-130/ac-131), типо-проверка language (ac-134), W034 на
  неизвестном теге (ac-135/ac-137), W035 на пользовательских кодах (ac-136), баланс внешней
  пары `<html>` (ac-137), V3–V5 на индексах подпапок (ac-151), дубликаты ответов (ac-139),
  обход до конца (ac-132/ac-133). Правка контракта не должна гасить соседние проверки —
  такие ноги красят стаб при перегибе.
- **Malformed input** — битый UTF-8 (ac-132/ac-133, обе стороны), битый `.comments.yaml`,
  невалидный ID (ac-129), разорванный переносом тег (ac-144), пустое значение `code`
  у `<icon code=""/>` — слепая зона `code="([^"]+)"`, `"true"` строкой и `false` (ac-138), null/число/
  пустая строка в language (ac-134), значение вне enum и плоская нотация на индексе (ac-151),
  значение по коду в верхнем регистре (ac-136, членство по `code.lower()`).
- **N/A-строк по карте нет**: каждый AC брифа получил стаб; процедурных AC в карте нет.

## Переводы существующих ассертов (NFR-084 — перевод, не удаление)

| Файл:строки до | Старая семантика | Новая семантика |
|---|---|---|
| `tests/gramax/writer-sync-470/ac-086-fragment-canonical-legacy.sh:57-61` (пин после перевода — `:57-62`) | `schemaVersion gramax-tags.json == 2` (ADR-0024 Р3) | `== 3` (ADR-0026 Р2, pairedTags += table/tr/td); заголовочный комментарий согласован; red on 7553da1 |
| `tests/gramax/catalog-validator/ac-030-icon-lucide-boundary.sh` (файл целиком) | вывод НЕ упоминает `lucide-zap` (warden AC-157, BR-013) | голый `zap` (в реестре) — W035 НЕТ; `lucide-zap` без файла — W035 С подсказкой «префикс»; фикстура `validators-parity/icons-lucide/article.md` дополнена `<icon code="zap"/>`; red on 7553da1 |
| `plugins/gramax/scripts/tests/test_validators_parity.py:78-91` (`XlucidePrefixBoundaryTests`) | `lucide-zap` — библиотечный, упоминаний нет | `lucide-zap` даёт W035 с подсказкой; `xlucide-zap` остаётся пользовательским; red on 7553da1 |
| `plugins/gramax/scripts/tests/test_validate_structure.py:101-103` (`test_v2_index_with_properties`) | ERROR «не должен содержать properties» на фикстуре `fixtures/bad/index-with-properties/` | тест заменён классом `IndexPropertiesVerdictTests`: перенесённая фикстура чиста в `good/`, V3–V5 применяются к индексам подпапок, индекс корня вне находок; red on 7553da1 |
| фикстура `plugins/gramax/scripts/tests/fixtures/bad/index-with-properties/` | носитель V2-нарушения в `bad/` | перенесена в `good/index-with-properties/`; `_index.md` получил ссылку на свою статью (гасит шум сироты) и легальный заголовок; V4/V5-ноги — новая общая фикстура `tests/gramax/catalog-validator/fixtures/ac-151-properties-index/` (прецедент ADR-0020: один набор фикстур на два прогона) |

Сопутствующий эффект, зафиксированный сознательно: `GoodCatalogTests.test_good_catalog_passes`
(пустой stdout на `fixtures/good/`) красный на 7553da1 — перенесённая фикстура сегодня даёт
V2-находку; зеленеет тем же циклом Решения 5. Носитель красного — переведённый
`test_good_index_with_properties_passes_clean` с именованной причиной; смок-тест не
ослаблялся (остался «exit 0 и пустой stdout»).

Строка AC-066 (после `gramax-o0q.19` — AC-157) помечается в требовании паритета владельцем —
не переписывается (таблица дизайна §4); стаб ac-030 в этой задаче уже переведён, что и есть
superseded-часть на стороне suite.

## Верификация красного состояния (замер 2026-11-23, HEAD 7553da1)

Каждый стаб запущен по отдельности (`bash tests/gramax/<suite>/<стаб>.sh`); pytest —
`uv run --with pytest python3 -m pytest -q <файл>`. Все падения — на именованных ассертах,
не на импорте/синтаксисе/отсутствии файла; `bash -n` на всех стабах чист.

| Стаб | exit | Красная нога (первая) |
|---|---|---|
| comments/ac-129 | 1 | «duplicate comment id … expected '0', got '1'» (3 ассерта) |
| comments/ac-130 | 1 | parse: `anchor_not_found`; skills: самозакрытой формы и слова «канон» нет (8) |
| comments/ac-132 | 1 | validate_comments: traceback-нога (9) |
| comments/ac-139 | 1 | тишина на ответе без user.id; шаблона с id нет (3) |
| comments/ac-144 | 1 | иллюстрация в коде прочитана как разметка (4) |
| catalog-validator/ac-131 | 1 | «unpaired `<comment>`» на XML-форме (2) |
| catalog-validator/ac-133 | 1 | Traceback вместо E036; bait-находки нет (7) |
| catalog-validator/ac-134 | 1 | «missing field: language»; `docRootOptionalFields` нет (5) |
| catalog-validator/ac-135 | 1 | W034 на table/tr/td; schemaVersion 2 (7) |
| catalog-validator/ac-136 | 1 | W035 на голых кодах; реестра нет (9) |
| catalog-validator/ac-137 | 1 | W034/W035 внутри html-блока (5) |
| catalog-validator/ac-138 | 1 | ERROR при true; старая формулировка; ключа нет (12) |
| catalog-validator/ac-148 | 1 | 3 W034 на docs/ (2) |
| catalog-validator/ac-151 | 1 | V2 на всех индексах; V4/V3/V5 молчат (8) |
| catalog-validator/ac-030 (перевод) | 1 | W035 на голом zap; lucide-zap молчит (4) |
| render-linter/ac-132 | 1 | Traceback вместо «ERROR L0: …» |
| render-linter/ac-135 | 0 | варден — зелёный (см. таблицу покрытия) |
| render-linter/ac-137 | 1 | ERROR на приманках внутри блока |
| plugin-contract/ac-140 | 1 | README 4.8.0 != 4.9.0; th в 500-перечислении; th+WARN нет (3) |
| pytest test_validate_structure.py | 1 | 3 failed / 13 passed — только переведённые классы |
| pytest test_validators_parity.py | 1 | 1 failed / 3 passed — только перевод Xlucide |

Достижимость зелёного проверена симуляцией пост-состояния: докстринг-извлечение ac-140
на исправленном тексте (th вне первого сентенса, th+WARN рядом) — обе ноги зелёные;
фикстурные позиции байтов вычисляются стабами из самих байтов (`0xd0`, start/size), не
захардкожены.

## Что должен сделать Dev, чтобы стабы позеленели (контракт вызова)

Порядок и файлы — бриф Dev (§7 дизайна); здесь — только привязка к стабам:

1. **Решение 1** (`gramax-4jf.6`): `gramax-catalog-rules.json` по §2.1 → зеленит ac-134.
2. **Решение 2** (`gramax-4jf.7`): `gramax-tags.json` schemaVersion 3 → зеленит ac-135,
   ногу ac-086 (пин), `ac-135-table-balance-single-finding` остаётся варденом.
3. **Решение 3** (`gramax-4jf.8`): `gramax-lucide-icons.json` (§3, контрольные дайджесты) +
   `check_icons` → зеленит ac-136, ac-030, pytest-паритет.
4. **Решение 4** (`gramax-4jf.10`): `indexPolicy.subfolderOptionalFlag` + чтение флага +
   формулировка §2.4 → зеленит ac-138.
5. **Решение 5** (`gramax-4jf.2`→`.1`): снятие V2, V3–V5 для индексов подпапок → зеленит
   ac-151, pytest `IndexPropertiesVerdictTests`, смок `GoodCatalogTests`.
6. **Решение 6** (`gramax-4jf.5`): примитив чтения + E036/«ERROR L0: …» дословно → зеленит
   ac-132 (обе стороны), ac-133.
7. **Комментарии** (`gramax-4jf.3`, `.4`, `.9`, `.11`, `.13-нога`): маска кода, обе блочные
   формы, info-строка позиций, warning user.id, шаблон и навыки → зеленит ac-129, ac-130,
   ac-139, ac-144, leg навыков ac-130.
8. **Тексты** (`gramax-4jf.12`): README-версия, докстринг th-WARN → зеленит ac-140;
   **плейсхолдеры docs/** (AC-148) — формулировка или code-span на трёх строках §6 →
   зеленит ac-148. docs/ стабами не правится.

## Отклонения и именованные решения

- **`ac-144-comments-illustrations-not-markup.sh` носит номер AC-144** — comments-нога не
  имеет собственного AC: её принимает порог «0 ERROR validate_comments на docs/» (FR-220),
  чей гейт-шаг — предмет ADR-0027 и вне мандата QA-author этой задачи. Имя выбрано по AC,
  который стаб питает; в шапке стаба привязка названа. Альтернатива «стаб без AC-номера»
  нарушила бы контракт карты покрытия.
- **Три зелёных рождения** — все вардены с обоснованием, ни один не «подогнан»: ac-135
  (BR-027 уже соблюдён и обязан пережить расширение `pairedTags`), нога «код не переключает
  маску» в ac-137 (сегодня её несёт `_mask_code`, обязана пережить посадку html-маски),
  нога «запасной текст не звучит» в ac-140 (защита от «фикса» переносом fallback-текста в
  документацию). Остальные зелёные ноги — контроли внутри красных стабов (перечислены в
  таблице покрытия), не отдельные стабы.
- **Стабы и фикстуры не читают приватный корпус сравнения**: все числа фактов (999, 90, 43,
  16) живут в требовании и ADR-0026 как замеры приёмки; фикстуры — собственный текст,
  позиции байтов вычисляются из самих фикстур.
- **Суффикс `-render`/-`mask`/-`traversal`** различает стороны одного AC между suite
  (ac-132/ac-133 — UTF-8 на двух валидаторах, ac-135/ac-137 — по стабу на suite) — 1:1
  «AC → файл» внутри каждой suite сохранён.
- **Вне мандата остались**: README-строка `tests/gramax/writer-sync-470/README.md` (таблица
  ac-086 всё ещё называет «schemaVersion=2») и README-разделы сюит, правки которых ведёт
  Dev шагами 1–8; `render-quality/` — зона параллельного исполнителя, не читалась и не
  писалась. Оба пункта — координатору на триаж.

## Гигиена

- Сетевых вызовов нет: все стабы — локальные файлы, `uv run` локальных скриптов (PEP-723),
  python3 stdlib для JSON/байтов. Личных данных нет: в фикстурах — служебные адреса вида
  `author@example.com` (RFC 2606), литералов реального хоста нет.
- Файлы плагина стабами только читаются (кроме двух pytest-файлов и переноса фикстуры,
  поимённо разрешённых брифом как переводы NFR-084); `render-quality/` и чужой ADR-0027 не
  затронуты.
- Размеры: стабы 40–120 строк, модульная форма, один `FAIL`-счётчик на файл; байтовые
  фикстуры — по одному неверному байту 0xd0, позиция и размер вычисляются прогоном.
