# tests/gramax/render-linter/ — контракт `validate_render.py` (рендер-киллеры Gramax)

Suite поведенческого контракта линтера рендер-киллеров: AC-001…AC-021 требования
`docs/30-requirements/2026-08-12-render-killer-linter.md` (ADR-0019 Решение 4).
Запуск — `run.sh` (все `ac-*.sh`, rc≠0 при любом красном); подключён к
`scripts/check.sh --full` шагом 14.

**Калибровка 2026-11-21** (FR-196): вердикты линтера выровнены по факту рендера на
целевом портале — запись замера
`docs/60-implementation/acceptance/2026-11-21-render-calibration-validate-render.md`
(раздел «Решения»): note-in-cell и note-in-note понижены ERROR → WARN (сообщения —
«ширины плывут» / «схлопываются», не «сбой рендера»); многострочный `<colgroup>` —
новый детектор, ERROR (подтверждённый 500-киллер: «500 до правки, 200 после»);
однострочная форма остаётся легальной (allowlist colgroup/col, BR-002). AC-003,
AC-004 и AC-014 ниже ассертируют калиброванную правду; раздел «Критерии приёмки»
требования в части severity этих трёх AC читается вместе с записью замера
(правки docs/ самим suite'ом не делаются).

## Инвентарь

| Тест | AC | Ассерт |
|---|---|---|
| ac-001-th-positive.sh | AC-001 (FR-104) | `<th>` вне кода → ERROR L с подсказкой `<td>` + `header="row"`, rc=1 |
| ac-002-inline-note.sh | AC-002 (FR-105) | инлайновый `<note>…</note>` → ERROR L, указание на блочный формат, rc=1 (остаётся ERROR — калибровка его не трогала) |
| ac-003-note-in-cell.sh | AC-003 (FR-106) | **калибровка 2026-11-21**: `<note>` внутри `<td>/<th>` → WARN L14 («ширины колонок плывут», подсказка инлайн-замены), rc=0, ERROR по конструкции нет; фикстура не менялась |
| ac-004-note-in-note.sh | AC-004 (FR-107) | **калибровка 2026-11-21**: `<note>` вложен в `<note>` → WARN L9 («вложенные заметки схлопываются»), rc=0, ERROR по конструкции нет |
| ac-005-multiple-images.sh | AC-005 (FR-108) | два `![](` в строке → ERROR L, rc=1 |
| ac-006-unbalanced.sh | AC-006 (FR-109) | unbalanced `<note>`/`<tabs>` → ERROR с именами тегов и числами открыто/закрыто, rc=1 |
| ac-007-fenced-code.sh | AC-007 (FR-110) | fenced-код маскируется (теги/`![](`/`#` не флагаются), реальный `<th>` вне кода в той же фикстуре ловится |
| ac-008-inline-code.sh | AC-008 (FR-110) | inline-код `` `<note>` ``/`` `<tabs>` ``/`` `<th>` `` не флагается, rc=0 (регрессия на 11 ложных ERROR исходника) |
| ac-009-h1-warn.sh | AC-009 (FR-111) | H1 в теле → WARN (не ERROR), rc=0 |
| ac-010-title-quoting.sh | AC-010 (FR-112) | frontmatter `title` с `: ` без кавычек → WARN; в кавычках → чисто, rc=0 |
| ac-011-th-severity.sh | AC-011 (FR-113) | severity `<th>` = ERROR безусловно (не WARN), rc=1 |
| ac-012-dedup-w034.sh | AC-012 (FR-114) | `validate_structure.py` молчит по `<th>` (нет W034), рендер-линтер даёт ERROR — одна находка на дефект (BR-004) |
| ac-013-exit-codes.sh | AC-013 (FR-113, NFR-001) | каталог без ERROR, но с WARN → rc=0; каталог с ERROR → rc=1 |
| ac-014-colgroup-allowlist.sh | AC-014 (FR-115) | **калибровка 2026-11-21, обе стороны**: (а) многострочный `<colgroup>` → ERROR L7 «Многострочный `<colgroup>` → HTTP 500», rc=1; (б) однострочный `<colgroup>/<col>` — allowlist (BR-002) ни ERROR, ни WARN, rc=0; фикстура (б) — `fixtures/ac-014-colgroup-single-line.md`, конструкция зеркалит `tests/gramax/render-quality/fixtures/control-colgroup-single-line.md` |
| ac-015-emoji-h2.sh | AC-015 (FR-116) | эмодзи в `##`-заголовке не флагается, rc=0 |
| ac-016-brackets-attr.sh | AC-016 (FR-117) | скобки и спецсимволы в XML-атрибутах не флагаются, rc=0 |
| ac-017-multipara-td.sh | AC-017 (FR-118) | многоабзацная ячейка `<td>` (пустые строки между абзацами) не флагается, rc=0 |
| ac-018-dogfooding.sh | AC-018 (FR-119) | собственный `docs/` проходит линтер без ERROR (WARN допустимы) |
| ac-019-precommit-gate.sh | AC-019 (FR-119) | `validate_render.py` подключён к `check-gramax.sh` — гейт исполняет шаг, не ручной разовый прогон |
| ac-020-fast-green.sh | AC-020 (NFR-004) | `scripts/check.sh --fast` зелёный с рендер-линтером |
| ac-021-existing-suites.sh | AC-021 (NFR-003) | orphan-references и nauta-integration остаются зелёными |
| ac-132-broken-utf8-render.sh | AC-132 волны-3 (FR-212) | битый UTF-8: `FAIL <путь>` + дословная `ERROR L0: Файл не является валидным UTF-8 (байт 0xd0 на позиции P из S)`; без traceback; ERROR bait-файла и OK чистого присутствуют; rc=1. Дизайн волны-3 §2.4/ADR-0026 Р6 | 🔴 КРАСНЫЙ — red on 7553da1 (UnicodeDecodeError) |
| ac-135-table-balance-single-finding.sh | AC-135 волны-3 (FR-214, BR-027) | баланс table/tr/td несёт только validate_render: незакрытый `<td>` — ровно одна баланс-находка; validate_structure не дублирует; валидная таблица чиста | 🟢 **ЗЕЛЁНЫЙ С РОЖДЕНИЯ — warden BR-027**: поведение уже в дереве (замер 2026-11-23); сторожит от задвоения при расширении pairedTags и от исчезновения баланса |
| ac-137-html-block-render.sh | AC-137 волны-3 (FR-216) | содержимое `<html>…</html>` вне построчных проверок и баланса (инлайновый `<note>`, незакрытый `<td>` внутри блока — rc=0); `<html>` в inline-коде и fenced-блоке маску не переключает — настоящий `<th>` после упоминаний ловится (варден) | 🔴 КРАСНЫЙ (маски html-блока нет; red on 7553da1), нога вардена зелёная |
| ac-137b-html-nested-render.sh | AC-137b волны-3 (FR-216) | вложенность: инлайновый `<note>` внутри внутреннего блока и незакрытый `<td>` в хвосте обёртки (между `</html>` внутреннего и `</html>` обёртки) — rc=0; незакрытый `<td>` вне блоков — rc=1 (варден) | 🔴 КРАСНЫЙ на d6ccab7 (регрессия замера 2026-11-23: хвост обёртки оставался видимым — ложный ERROR баланса) |

## Запуск

    bash tests/gramax/render-linter/run.sh                     # весь suite
    bash tests/gramax/render-linter/ac-003-note-in-cell.sh     # одиночный тест

Фикстуры — `fixtures/ac-*.md`. Учёт консистентности: этот README — единственное место
инвентаря suite'а; ни один тест suite'а не ассертирует счётчик тестов/фикстур, поэтому
появление `fixtures/ac-014-colgroup-single-line.md` отдельной синхронизации не требует.
