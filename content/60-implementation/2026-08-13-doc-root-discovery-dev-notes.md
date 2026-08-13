---
title: "Dev notes: рекурсивное обнаружение `.doc-root.yaml` и типизация полей (ADR-0020)"
order: 4
properties:
  - name: Тип контента
    value: [Урок]
  - name: Статус
    value: [Done]
  - name: Плагин
    value: [gramax, marketplace]
---

# Dev notes: рекурсивное обнаружение `.doc-root.yaml` и типизация полей (ADR-0020)

Фиксирует «Тип контента: Урок» за неимением отдельного enum-значения для заметок реализации —
тот же приём, что `2026-08-11-validation-contract-dev-notes.md`.

**Требование:** [Контракт .doc-root.yaml: рекурсивное обнаружение и типизация title](../30-requirements/2026-08-13-doc-root-discovery-contract.md) (FR-120…FR-123)
**ADR:** [Рекурсивное обнаружение .doc-root.yaml и типизация обязательных полей в validate_structure.py](../00-project/adr/0020-doc-root-recursive-discovery.md) (Решения 1–3, 5)
**Тест-дизайн:** `tests/gramax/catalog-validator/ac-021…ac-024.sh` + фикстуры
`tests/gramax/catalog-validator/fixtures/{nested-doc-root-discovery,doc-root-title-type,doc-root-parse-error,nested-doc-root-demarcation}`

**Периметр этой поставки Dev:** `plugins/gramax/scripts/validate_structure.py` и его тесты
(`test_validate_structure.py`, ac-021…ac-024). Сознательно НЕ тронуто: CHANGELOG, `plugin.json`,
`marketplace.json`, README (OPS-001, Tech-writer отдельно); само требование и ADR-0020 (приняты);
`scripts/` в корне (nauta-территория).

## Что было сделано (по FR)

1. **FR-120** — `validate()` теперь обходит всё дерево переданного пути, каждый найденный
   `.doc-root.yaml` валидируется как отдельный root полным suite'ом (`_validate_catalog_root`).
   Исключения обхода — явный список: `.git`/`.gramax`/`node_modules` по имени каталога,
   `tests/**` и `plugins/gramax/scripts/tests/fixtures/**` по относительному пути. Первичный
   root не исключается никогда. Граница ownership: `_collect_md_files`, `_collect_links`,
   `check_subfolders_have_index`, `check_garbage`, `check_no_drawio`, `check_unsupported_markup`
   не спускаются в поддеревья вложенных root; ресурсные проверки (broken-link/image/diagram)
   фильтруют источники через `_parse_resources` (lib `parse_md_resources` не трогался —
   фильтрация по `source` на стороне валидатора).
2. **FR-121** — `check_doc_root` проверяет тип: значение обязательного поля (`title`/`language`/
   `syntax`) обязано быть непустой строкой. `dict`/`list`/`bool`/`int`/`float`/`date`/`null`/
   пустая строка → error `invalid type for field "...": expected non-empty string, got <тип>
   (строка N: <raw>)`. Номер строки значения — из `yaml.compose` (не из `safe_load`), raw-текст —
   из исходника. `missing field: ...` сохранён для отсутствующего ключа.
3. **FR-122** — ранний `return` при `yaml.YAMLError` убран для существующего файла: прогон
   продолжается (минимум `check_placeholders` обязателен — работает по raw-тексту, не по AST).
   Номер строки/колонки — из `problem_mark.line`/`.column` (fallback `str(e)`). Отсутствие
   `.doc-root.yaml` на переданном корне сохраняет прежнее поведение (error + прекращение).
4. **FR-123** — эвристика по raw-строке `^(\w[\w-]*)\s*:\s*(\{\{[^{}\n]+\}\})(.*)$`: токен
   на позиции значения поля дополняет parse-error-находку подсказкой закавычивания
   (`закавычьте значение: title: "{{PROJECT_NAME}}" (пример: ...)`). Parse-error-находка
   поглощает placeholder-находку того же токена (`check_placeholders` получает suppressed-set);
   прочие токены файла продолжают давать собственные placeholder-находки.

## Что было неочевидно

### 1. `[^{}\n]+` в эвристике FR-123 усекает токен на одной `}` — двойная находка на дефект

Первая версия regex была `^(\w[\w-]*)\s*:\s*(\{\{[^{}\n]+\})(.*)$`. Для `title: {{PROJECT_NAME}}`
это давало token=`{{PROJECT_NAME}` (одна закрывающая скобка) и rest=`}`: suggestion получался
`title: "{{PROJECT_NAME} }"`, а главное — suppressed-токен не совпадал с `{{PROJECT_NAME}}`,
находимым `_PLACEHOLDER_RE`, и placeholder-находка дублировала parse-error (2 находки на дефект,
нарушение BR-004). Фикс: `\}\}` в конце группы токена. Тест ac-023 усилен явным негативным
ассертом «placeholder-находки того же токена нет» — иначе тест зелёный по причине
«grep-совпал пример из подсказки», не по BR-004.

### 2. `--groups` таксономия не менялась — находки FR-120…123 сели в `content`

Паттерн группы `content` (`missing|invalid|плейсхолдер|placeholder`) уже матчит
`invalid yaml: ...`, `invalid type for field ...`, `missing field: ...` и подсказку FR-123.
Проверено `--groups`-прогоном на фикстурах ac-022/ac-023 — всё в `[content] incorrects-content`,
`[other]` отдаёт только pre-existing schema-warning (файл без `properties`).

### 3. `bash scripts/check.sh --full` красный ДО этой задачи — shellcheck в чужом файле

`--full` падает на `shellcheck SC2034` в `tests/gramax/render-linter/ac-012-dedup-w034.sh:20`
(`RC=$?` не используется). Файл последний раз менялся в `562325e` (render-killer-linter) и
этой задачей не трогался — `git status` подтверждает. Мои ac-021…ac-024 проходят `shellcheck`
начисто (прогнано явно). Требуемые гейты задачи (`--fast`, `catalog-validator/run.sh`, pytest)
зелёные; `--full`-краснота — предсуществующая, не регрессия этой поставки (тот же класс, что
задокументирован в `2026-08-13-cross-catalog-retraction-dev-notes.md` §3).

### 4. `_index.md`-правки и untracked ADR/требование — артефакты SA/BA, не Dev

`content/00-project/adr/_index.md` и `content/30-requirements/_index.md` регистрируют ADR-0020
и требование FR-120…123 (заготовка задачи). Dev их не редактировал; `git diff` показывает
только строки регистрации.

### 5. `load_property_schema` на непарсящемся `.doc-root.yaml` даёт pre-existing warning

Для битого файла `load_property_schema` возвращает `None` (YAMLError), и появляется warning
«schema использует экспериментальный формат values» — слегка вводящее в заблуждение сообщение
для parse-ошибки, но это существующее поведение (не трогается этой задачей; warning, exit не
меняет).

## Edge cases, покрытые реализацией (не все — отдельными фикстурами)

- `date` (`title: 2026-01-01` → `datetime.date`), `list`, пустая строка — типы, которые ADR
  называет дефектными; `_value_type_name` их называет корректно (`date`/`list`/`empty string`).
  Acceptance-фикстуры ac-022 покрывают float/bool/null/dict + quoted по списку требования;
  date/list/empty — только в коде.
- Вложенность root-в-root: каждый `.doc-root.yaml` (любой глубины) валидируется своим прогоном;
  поддерево ближайшего предка принадлежит только ему (ownership).
- Первичный root, чьё имя совпадает с исключаемым (`tests`, `node_modules` и т.п.), не
  исключается: `_is_excluded_walk_path` считает относительный путь от переданного корня, у
  самого корня частей нет.
