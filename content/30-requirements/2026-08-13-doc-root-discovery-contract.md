---
title: "Контракт .doc-root.yaml: рекурсивное обнаружение и типизация title"
order: 12
status: draft
date: 2026-08-13
plugin: gramax
properties:
  - name: Тип контента
    value: [Требование]
  - name: Статус
    value: [Draft]
  - name: Плагин
    value: [gramax]
---

# Контракт `.doc-root.yaml`: рекурсивное обнаружение и типизация title

## JTBD

Когда я сопровождаю репозиторий каталога Gramax и прогоняю `validate_structure.py`
перед публикацией, а он отвечает «чисто», хотя редактор `editor.nau.im` у всех
пользователей воркспейса не открывается вообще, — я (сопровождающий каталога, а
также владелец воркспейса, к которому идут с «Gramax сломался») хочу, чтобы
валидатор проверял **все** `.doc-root.yaml` репозитория и типы их полей, а не
только тот, что лежит в переданном корне, чтобы невалидный YAML в служебной папке
не ронял редактор для всего воркспейса и находился до пуша, а не по жалобе
разработчика Gramax.

## Описание

Инцидент 2026-08-13: редактор Gramax не открывался; разработчик Gramax
локализовал причину как «у одного из репозиториев в `.doc-root.yaml` в поле
`title` не строка, а какое-то невалидное значение».

Найдено 24 файла `.doc-root.yaml` в 12 подключённых каталогах со строкой вида

```yaml
title: {{PROJECT_NAME}} — KB команды
```

`{{` в YAML открывает flow mapping, поэтому `title` — не строка, а словарь
(Python: `ParserError`/`ConstructorError`; JS-парсер в мягком режиме отдаёт
объект). Все 24 файла лежали **не** в корне каталога, а в скопированной из
шаблона папке `examples/<профиль>-example/content/`.

Ключевой факт: **Gramax ищет catalog root, сканируя весь репозиторий**, а не
только `content/`. Поэтому он находил и парсил эти вложенные `.doc-root.yaml` —
и падал. При этом `validate_structure.py content` на тех же репозиториях давал
exit 0.

Три пробела относительно реального поведения Gramax:

1. **Область обнаружения.** `validate()` (`validate_structure.py:447`) читает
   ровно `root/.doc-root.yaml` через `check_doc_root()`. Вложенные
   `.doc-root.yaml` глубже по дереву не валидируются никогда. Валидатор про них
   знает — `check_orphans()` помечает такие поддеревья `in_scope=False`, — но
   только чтобы их **исключить**. Gramax же, наоборот, их включает.
2. **Типизация полей.** `check_doc_root()` проверяет лишь присутствие ключа
   (`field not in data`), не тип. `docRootRequiredFields = [title, language, syntax]`
   в `gramax-catalog-rules.json` проходит при `title: 4.21` (float),
   `title: 2026-01-01` (date), `title: yes` (bool), `title: {a: b}` (dict) —
   ровно тот класс дефекта, который описал разработчик Gramax.
3. **Слепое пятно фикстуры.** `tests/gramax/catalog-validator/fixtures/placeholder-leak/`
   покрывает только **закавыченный** плейсхолдер (`code: "{{TSN_CODE}}"`) —
   YAML валиден, срабатывает `check_placeholders()` (FR-046). Незакавыченный
   `{{...}}`, при котором файл не парсится вообще, ни одной фикстурой не покрыт.

## Факты (верификация 2026-08-13)

1. `validate_structure.py:70-83` — `check_doc_root()` читает только
   `root / ".doc-root.yaml"`; проверка полей — `field not in data`, без проверки типа.
2. `validate_structure.py:447-448` — при неудаче `check_doc_root()` (в т.ч.
   `invalid yaml`) `validate()` делает ранний `return`: остальные проверки, включая
   `check_placeholders()`, не выполняются. Диагностика схлопывается до одного
   сообщения `invalid yaml: <текст исключения pyyaml>`.
3. `gramax-catalog-rules.json` → `docRootRequiredFields: ["title", "language", "syntax"]`.
4. Рекурсивный скан 86 каталогов, подключённых к `ges.nau.im`: 24 битых
   `.doc-root.yaml` в 12 репозиториях (`bpm-2`, `kanboard`, `calendar-booking`,
   `dynamic-fields`, `tzt-widget`, `jar`, `moex`, `process-management`,
   `sa_assistant`, `cockpit`, `foodplex`, `gramax-user-docs`) — все по пути
   `examples/{kb-team,project}-example/content/.doc-root.yaml`. Соседние примеры
   (`course`, `product`, `methodology`, `kb-product`) валидны: там плейсхолдеры
   либо заполнены, либо закавычены.
5. В тех же репозиториях `examples/` даёт по 7–8 дополнительных catalog root,
   которые Gramax обнаруживает как отдельные каталоги.

## Функциональные требования

**FR-120. Рекурсивное обнаружение catalog root.** Валидатор обязан находить все
файлы `.doc-root.yaml` в дереве переданного пути, а не только в его корне, и
валидировать каждый как catalog root. Пути, исключённые из обхода (`.git`,
`.gramax`, `node_modules`), задаются явным списком.

**FR-121. Типизация обязательных полей `.doc-root.yaml`.** Для каждого поля из
`docRootRequiredFields` проверяется не только присутствие, но и тип. `title` —
непустая строка; значение другого типа (dict, list, bool, int, float, date, null)
— `error` с указанием фактического типа и исходной строки файла.

**FR-122. Невалидный YAML не глушит остальную диагностику.** При
`yaml.YAMLError` в `.doc-root.yaml` валидатор обязан дополнительно прогнать
текстовые проверки (как минимум `check_placeholders`) и вывести номер строки и
колонку из исключения pyyaml, а не только `str(e)`.

**FR-123. Подсказка по исправлению плейсхолдера.** Если невалидный YAML вызван
незакавыченным `{{...}}`, сообщение обязано предлагать конкретное исправление —
закавычивание (`title: "{{PROJECT_NAME}}"`), — а не только констатировать ошибку
парсинга.

## Критерии приёмки

**AC-036** (`tests/gramax/catalog-validator/ac-021-nested-doc-root-discovered.sh`).
Фикстура: валидный `content/.doc-root.yaml` + битый
`examples/project-example/content/.doc-root.yaml` с незакавыченным
`title: {{PROJECT_NAME}} — База знаний`. Запуск валидатора на корне фикстуры →
exit ≠ 0, в выводе фигурирует путь вложенного файла. Регресс-якорь инцидента
2026-08-13: до FR-120 эта фикстура даёт exit 0.

**AC-037** (`tests/gramax/catalog-validator/ac-022-doc-root-title-type.sh`).
Фикстуры с `title: 4.21`, `title: yes`, `title:` (null) и `title: {a: b}` при
валидном в остальном YAML → каждая даёт `error`, сообщение содержит фактический
тип. Фикстура с `title: "4.21"` → чисто.

**AC-038** (`tests/gramax/catalog-validator/ac-023-unparseable-doc-root-diagnostics.sh`).
Фикстура с незакавыченным `{{...}}` в `.doc-root.yaml` → сообщение содержит
номер строки, слово «плейсхолдер»/`placeholder` и пример исправления с кавычками.

**AC-039** (`tests/gramax/catalog-validator/ac-024-nested-doc-root-orphan-demarcation.sh`).
Существующий контракт `check_orphans` (`in_scope=False` для вложенных
`.doc-root.yaml`-поддеревьев) не ломается: вложенный каталог валидируется как
отдельный root, но его статьи не считаются orphan-ами внешнего каталога. Дефект
даёт ровно одну находку, не две.

**AC-040** (догфудинг). `ac-001-dogfood-clean-exit.sh` остаётся зелёным: в самом
`gramax-plugin` есть `.doc-root.yaml`-фикстуры под `tests/**` и
`plugins/gramax/scripts/tests/fixtures/**`, которые после FR-120 попадут в область
обнаружения. Требуется явное решение — исключать пути фикстур из обхода или
чинить фикстуры; выбор зафиксировать в ADR.

## Открытые вопросы

1. Нужен ли отдельный уровень для «лишний catalog root в служебной папке»
   (`examples/`, `tests/fixtures/`)? Формально YAML валиден, но Gramax показывает
   пользователю 7–8 мусорных каталогов. Кандидат: `warning` с отдельным кодом.
2. Совместимость с `--groups`: под какую группу таксономии
   `CatalogErrorGroups` попадают находки FR-120/FR-121.
