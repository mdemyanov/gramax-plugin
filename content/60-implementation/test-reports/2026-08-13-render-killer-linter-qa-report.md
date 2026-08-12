---
title: "QA Report — линтер рендер-киллеров (validate_render.py, 4.4.0)"
order: 9
properties:
  - name: Тип контента
    value: [Тест-отчёт]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# QA Report — линтер рендер-киллеров Gramax (`validate_render.py`, 4.4.0)

**Дата прогона:** 2026-08-13
**Ветка/дерево:** `main`, HEAD `9d66c0a` + незакоммиченная фича (спека, ADR-0019, реализация, suite — рабочее дерево)
**Tester:** QA-runner (независимый прогон, не полагался на заявленный PM/Dev результат)
**Требование:** [Линтер рендер-киллеров Gramax](../../30-requirements/2026-08-12-render-killer-linter.md) (FR-104…FR-119, AC-001…AC-021, BR-001…BR-004, NFR-001…NFR-008)
**ADR:** [0019-render-killer-linter.md](../../00-project/adr/0019-render-killer-linter.md) (решения Р1–Р9)
**AT-design (qa-author):** отдельного файла нет — AC-001…AC-021 живут в теле требования; suite `tests/gramax/render-linter/` (ac-001…ac-021.sh) покрывает их 1:1

---

## Summary

| Suite/проверка | Команда | Passed | Failed | Skipped | Exit |
|---|---|---|---|---|---|
| `render-linter` (приёмка, новая фича) | `bash tests/gramax/render-linter/run.sh` | 21 | 0 | 0 | `0` |
| `orphan-references` (regression) | (внутри `--full`) | PASS | 0 | — | `0` |
| `nauta-integration` (regression) | (внутри `--full`) | 8 | 0 | 0 | `0` |
| `plugin-contract` (regression) | (внутри `--full`) | 7 | 0 | 0 | `0` |
| `doc-paths` (regression) | (внутри `--full`) | 2 | 0 | 0 | `0` |
| `catalog-validator` (regression) | (внутри `--full`) | 20 | 0 | 0 | `0` |
| `mermaid-adoption` (regression) | (внутри `--full`) | 10 | 0 | 0 | `0` |
| `writer-consumer-rules` (regression) | (внутри `--full`) | 11 | 0 | 0 | `0` |
| `link-form-resolver` (regression) | (внутри `--full`) | 8 | 0 | 0 | `0` |
| `link-form-migration` (regression) | (внутри `--full`) | 7 | 0 | 0 | `0` |
| **Итого (AC-скрипты)** | | **94** | **0** | **0** | — |
| Композит `check.sh --fast` (NFR-004 / AC-020) | `bash scripts/check.sh --fast` | — | — | — | `0` |
| Композит `check.sh --full` (14 шагов, 94 AC внутри) | `bash scripts/check.sh --full` | — | — | — | `0` |

- **passed:** 94 (21 render-linter + 73 регрессия по 8 существующим suite)
- **failed:** 0
- **skipped:** 0
- **total:** 94 AC-скриптов + 6 не-AC шагов `--full` (whitespace, json, content, render, shellcheck, submodule)
- **duration:** `validate_render.py content` ≈ 0.24 c; `validate_structure.py content` ≈ 0.56 c; suite `render-linter` ≈ 6.5 c; `check.sh --full` целиком — в пределах ~1–2 мин
- **Итог одной строкой:** полный пак (не subset) прогнан независимо и дал 100% зелёный результат — 21/21 по новой фиче и 73/73 по регрессии; демаркация W034/`<th>` подтверждена буквальным прогоном обоих валидаторов; догфудинг на собственном `content/` — exit 0, ERROR=0 на 72 файлах. Находок, блокирующих приёмку, нет. Рекомендация — **merge**.

---

## Прогон suite → команда → код возврата (честный `$?`)

| # | Проверка | Команда | Код возврата |
|---|---|---|---|
| 1 | Fast gate (AC-020/NFR-004) | `bash scripts/check.sh --fast` | `exit=0` |
| 2 | Full gate (14 шагов, агрегатор) | `bash scripts/check.sh --full` | `exit=0` |
| 3 | Render-linter suite (AC-001…021) | `bash tests/gramax/render-linter/run.sh` | `exit=0` (21/21) |
| 4 | Демаркация W034, прогон структурного валидатора на `<th>`-каталоге | `uv run plugins/gramax/scripts/validate_structure.py tests/gramax/render-linter/fixtures/ac-012-dedup-dir` | `exit=0`, W034 по `<th>` **нет** (молчит), WARN по `<table>`/`<tr>` — ожидаемо |
| 5 | Рендер-линтер на том же `<th>`-каталоге | `uv run plugins/gramax/scripts/validate_render.py tests/gramax/render-linter/fixtures/ac-012-dedup-dir` | `exit=1`, ERROR L8 `<th>` — ровно одна находка |
| 6 | Догфудинг (AC-018) | `uv run plugins/gramax/scripts/validate_render.py content` | `exit=0` (72 файла, ERROR=0, только H1-WARN) |
| 7 | Sanity allowlist `<colgroup>`/`<col>` (AC-014) | `uv run plugins/gramax/scripts/validate_render.py tests/gramax/render-linter/fixtures/ac-014-colgroup.md` | `exit=0` |
| 8 | Sanity allowlist эмодзи в `##` (AC-015) | `uv run plugins/gramax/scripts/validate_render.py tests/gramax/render-linter/fixtures/ac-015-emoji-h2.md` | `exit=0` |
| 9 | Sanity inline-код `<th>`/`<note>` (AC-008) | `uv run plugins/gramax/scripts/validate_render.py tests/gramax/render-linter/fixtures/ac-008-inline-code.md` | `exit=0` |
| 10 | Usage-контракт NFR-001: несуществующий путь | `uv run plugins/gramax/scripts/validate_render.py /nonexistent/path` | `exit=2` |
| 11 | Детерминизм NFR-002 | два прогона `validate_render.py content --errors-only`, `diff` выводов | идентично |
| 12 | Производительность NFR-005 | `time uv run …validate_render.py content --errors-only` | 0.24 c (< 1 c) |

---

## Regression analysis

Падений нет — классификация regression/new/flaky/env не потребовалась ни по одному тесту. Сверка с предыдущими зелёными состояниями:

- **`orphan-references`** — PASS, не изменялся в этой волне.
- **`nauta-integration`** — 8/8 PASS, не изменялся.
- **`plugin-contract`** — 7/7 PASS; включает ac-006 (манифесты согласованы, CHANGELOG несёт секцию текущей версии) — подтверждает Р9 (версия 4.4.0 в обоих манифестах).
- **`catalog-validator`** — 20/20 PASS; ac-018 (W034 обнаруживает неподдерживаемую разметку) и ac-019 (все gramax-fixtures дают ожидаемые коды W030–W034) подтверждают, что демаркация W034 (ADR-0019 Р3) и дедуп баланс-чека (Р6) не изменили семантику существующих проверок `validate_structure.py` — ровно санкционированные NFR-007 правки.
- **`link-form-resolver` / `link-form-migration`** — 8/8 и 7/7 PASS, не затронуты.

Регрессия структурного валидатора: экстракция `_mask_code` в `lib/md_code_mask.py` (Р5) семантически инвариантна — тело функции не менялось, suite `catalog-validator` (20/20, включая догфудинг и граничные фикстуры W030–W034) зелёный. Двойное срабатывание баланса не наблюдалось: unbalanced `note`/`tabs` в фикстуре AC-006 репортит только рендер-линтер (PASS).

---

## Performance snapshot (NFR-005)

| Метрика | Baseline (`validate_structure.py`) | Текущий (`validate_render.py`) | Дельта | Комментарий |
|---|---|---|---|---|
| Прогон на `content/` (72 файла) | 0.56 c | 0.24 c | −0.32 c | Оба < 1 c; NFR-005 («мгновенный, офлайн, без сети и модели») подтверждён |
| Suite `render-linter` (21 AC) | — (новый) | 6.5 c | — | В рамках `--full`, не-блокирующе |
| Exit-контракт | 0/1 (+2 при `--fix` без `--yes`) | 0/1/2 (NFR-001) | — | Проверен вручную: `exit=2` на несуществующем пути |
| Детерминизм | — | идентичен на 2 прогонах | — | NFR-002 подтверждён |

---

## Демаркация W034 / `<th>` (Р3, AC-012, BR-004) — прицельная проверка

На каталоге-фикстуре `tests/gramax/render-linter/fixtures/ac-012-dedup-dir/` (содержит `<th>Шапка</th>` на строке 8):

- `validate_structure.py` (W034): **молчит по `<th>`** — тег вошёл в `known_tags = {"drawio"} ∪ killerTags ∪ allowlistedTags` (производное от `gramax-render-rules.json`, не литерал). W034 репортит `<table>` и `<tr>` (WARN) — это genuinely-неподдерживаемая разметка, вне периметра демаркации, и не является `<th>`.
- `validate_render.py`: **ровно одна находка** — `ERROR L8: Тег <th> не поддерживается Gramax → HTTP 500. замените на <td>; шапку задаёт header="row" у <table>`.

Итого по гейту на дефект `<th>` — ровно одна находка (BR-004). Механизм структурный (ownership в контракте), не post-hoc-дедуп вывода — Р3 исполнен.

---

## Критерии приёмки

### AC-001…AC-021 (поведенческий контракт линтера)

| AC | FR/НФР | Suite-тест | Результат | Примечание |
|---|---|---|---|---|
| AC-001 | FR-104 `<th>` позитив | ac-001 | PASS | ERROR L10, подсказка `<td>` + `header="row"`, exit 1 |
| AC-002 | FR-105 инлайновый `<note>` | ac-002 | PASS | ERROR L8, указание на блочный формат, exit 1 |
| AC-003 | FR-106 `<note>` в ячейке | ac-003 | PASS | ERROR L14 (строка `<note>`, не `<td>`), exit 1 |
| AC-004 | FR-107 `<note>` в `<note>` | ac-004 | PASS | ERROR L9 (вложенный), exit 1 |
| AC-005 | FR-108 несколько `![](` | ac-005 | PASS | ERROR L8, exit 1 |
| AC-006 | FR-109 unbalanced | ac-006 | PASS | имена тегов + числа открыто/закрыто, exit 1 |
| AC-007 | FR-110 fenced-код | ac-007 | PASS | теги/`![](` в ```` ``` ```` не флагаются; реальный `<th>` вне кода ловится |
| AC-008 | FR-110 inline-код | ac-008 | PASS | inline `<note>`/`<tabs>`/`<th>` не флагаются — регрессия на факт 2 (11 ложных ERROR исходника) |
| AC-009 | FR-111 H1 в теле | ac-009 | PASS | WARN, exit 0 |
| AC-010 | FR-112 `title:` без кавычек | ac-010 | PASS | WARN; закавыченный — чисто |
| AC-011 | FR-113 severity `<th>`=ERROR | ac-011 | PASS | ERROR, не WARN, exit 1 |
| AC-012 | FR-114 dedup W034 | ac-012 | PASS | W034 молчит по `<th>`, рендер-линтер ERROR — одна находка (см. прицельную проверку) |
| AC-013 | FR-113 exit-коды | ac-013 | PASS | WARN-only → 0; с ERROR → 1 |
| AC-014 | FR-115 `<colgroup>`/`<col>` | ac-014 | PASS | ни ERROR, ни WARN, exit 0 |
| AC-015 | FR-116 эмодзи в `##` | ac-015 | PASS | ни ERROR, ни WARN |
| AC-016 | FR-117 скобки в атрибутах | ac-016 | PASS | `( ) [ ]` в XML-атрибутах не флагаются |
| AC-017 | FR-118 многоабзацная ячейка | ac-017 | PASS | `<td>` с пустыми строками не флагается |
| AC-018 | FR-119 догфудинг | ac-018 | PASS | `validate_render.py content` → exit 0, 72 файла, ERROR=0 |
| AC-019 | FR-119 pre-commit gate | ac-019 | PASS | команда присутствует в `check.sh` (шаг 2.6, suite 14) |
| AC-020 | NFR-004 `--fast` | ac-020 | PASS | `bash scripts/check.sh --fast` → exit 0 |
| AC-021 | NFR-003 существующие suite | ac-021 | PASS | `--full` зелёный, регрессия 73/73 |

**Все 21/21 AC — PASS.** Покрытие: каждый AC имеет отдельный suite-тест, 1:1 соответствие AC↔тест без дыр (полный список AC-001…AC-021 против тел `ac-001…ac-021.sh`).

### Решения ADR-0019 (Р1–Р9)

| Р | Решение | Статус | Как проверено |
|---|---|---|---|
| Р1 | Отдельный скрипт `validate_render.py` (контент-слой) | Принято | файл существует, вызывается независимо; `validate_structure.py` получает только санкционированные правки |
| Р2 | Гибрид: `gramax-render-rules.json` (данные) + логика в коде | Принято | контракт `schemaVersion:1` с `killerTags`/`balanceTags`/`allowlistedTags`; читается обоими валидаторами |
| Р3 | Демаркация W034: `known = {"drawio"} ∪ killerTags ∪ allowlistedTags` | Принято | прицельная проверка: W034 молчит по `<th>`/`<colgroup>`/`<col>`, ERROR — только рендер-линтер (BR-004) |
| Р4 | Интеграция: `--fast`-шаг + suite в `--full` | Принято | шаг 2.6 в `check.sh`; suite 14 в `check.sh`; `--fast` exit 0, `--full` exit 0 |
| Р5 | Общий примитив `lib/md_code_mask.py` (fenced+inline) | Принято | оба валидатора импортируют `_mask_code` из `lib/`; inline-код не даёт ложных ERROR |
| Р6 | Ownership баланса: рендер-линтер полный набор, `check_tags` = `pairedTags − balanceTags` | Принято | AC-006 PASS (unbalanced `note`/`tabs` — рендер-линтер); `catalog-validator` 20/20 — `html/comment` остались за `check_tags` |
| Р7 | Атрибуция MIT: `LICENSE.upstream.md` + заголовок + CHANGELOG | Принято | файл на месте (provenance, список изменений, полный MIT-текст); copyright-заголовок в шапке `validate_render.py`; запись в CHANGELOG 4.4.0 с атрибуцией (Всеволод Шадрин, MIT) |
| Р8 | Severity/exit: ERROR→1, WARN→0, usage→2 | Принято | `exit=1` по `<th>`, `exit=0` при WARN-only, `exit=2` на несуществующем пути; `--strict` отсутствует |
| Р9 | Версия 4.4.0 (Minor) + правка `marketplace.json` | Принято | `plugins/gramax/.claude-plugin/plugin.json` = 4.4.0; `.claude-plugin/marketplace.json` `metadata.version` = 4.4.0; `name`/`owner`/`plugins`/`source` не тронуты |

### NFR-001…NFR-008

| NFR | Требование | Статус | Примечание |
|---|---|---|---|
| NFR-001 | exit 0/1/2 | PASS | проверено вручную: 0 (WARN-only), 1 (ERROR), 2 (usage) |
| NFR-002 | детерминизм | PASS | два прогона на `content/` — вывод идентичен (diff пуст) |
| NFR-003 | не ломать существующие suite | PASS | `--full`: 73/73 регрессионных AC зелёные |
| NFR-004 | собственный `--fast` зелёный | PASS | `bash scripts/check.sh --fast` → exit 0 |
| NFR-005 | производительность | PASS | 0.24 c на 72 файлах (< 1 c), офлайн, без сети/модели |
| NFR-006 | Attribution MIT | PASS | `LICENSE.upstream.md` + CHANGELOG-запись + заголовок в файле |
| NFR-007 | граница правок `validate_structure.py` | PASS | diff ограничен демаркацией W034 + дедупом баланса + механической экстракцией `_mask_code` |
| NFR-008 | безопасность (локальный офлайн) | PASS | регэксп-скрипт, сетевых вызовов нет (наблюдение прогона) |

---

## Failed tests (детали)

Падений нет. Таблица пуста по факту:

| Test | Reason category | Probable cause | Action |
|---|---|---|---|
| — | — | — | — |

---

## Находки (низкая серьёзность, не блокер)

1. **`--errors-only` не полностью подавляет WARN-заголовки.** По рекомендации ADR-0019 Р4 «флаг `--errors-only` … чтобы принятый шум H1-WARN не спамил каждый pre-commit» — флаг есть, exit-контракт не меняется, но файлы без ERROR по-прежнему печатают строку `WARN <path>` (подавляются только детальные `warn L#:`). Для pre-commit-гейта это косметика (exit 0, stdout не критичен), НЕ дефект гейта и НЕ нарушение AC-019. Передано Dev как опциональный UX-полиш в бэклог; не блокирует приёмку.
2. **`validate_structure.py` репортит W034-WARN на `<table>`/`<tr>`** рядом с ERROR рендер-линтера по `<th>` (та же страница, каталог потребителя). Это соответствует Р3/Р6 (табличные теги вне демаркации не являются киллером), дубля по `<th>` нет. Не блокер.

---

## Рекомендация

- [x] **merge**
- [ ] block + назад в Dev
- [ ] re-run (flaky)

**Обоснование:** полный пак (не subset) прогнан независимо — `--full` 14 шагов, 94/94 AC-скриптов зелёные (включая новый `render-linter` 21/21 и регрессию 73/73 без изменения счёта), `--fast` exit 0, догфудинг exit 0 (ERROR=0 на 72 файлах), демаркация W034/`<th>` подтверждена прицельным прогоном обоих валидаторов (ровно одна находка на дефект, BR-004), exit-контракт 0/1/2 и детерминизм проверены вручную, версия 4.4.0 и атрибуция MIT на месте (Р9/Р7). Находки — только косметика (WARN-заголовки при `--errors-only`), без влияния на гейты и контракт. Классификация падений не потребовалась: failed = 0, flaky/env-подтверждений нет.
