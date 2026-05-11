# Acceptance: diagram-on-demand

**Дата:** 2026-05-08
**Spec:** docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md
**QA Report:** docs/qa-reports/2026-05-08-diagram-on-demand-qa-report.md
**Reviewer:** BA (acceptance mode)

---

## Примечание о нумерации

Номера тестовых файлов (`ac-NNN-*.sh`) не совпадают с номерами AC из spec. Соответствие установлено на основе содержимого тестов и комментариев в заголовках файлов. QA-отчёт использует нумерацию тестов, а не spec. Матрица ниже выстроена по spec-AC.

---

## AC coverage matrix

| AC (spec) | Описание из spec | Artifact (file:section) | Test (файл теста) | Semantic match | Notes |
|-----------|-----------------|------------------------|-------------------|----------------|-------|
| AC-001 | mermaid flowchart + syntax:XML → создаётся `<name>.svg`, в md вставляется `<mermaid>...</mermaid>` | `SKILL.md:Mermaid-путь/Генерация и вставка`; `insert_diagram_ref.sh:строки 80-86 (SYNTAX=XML → <mermaid>)` | `ac-004-mermaid-xml.sh` | ✅ | Тест проверяет: `insert_diagram_ref.sh --syntax XML --mermaid-dsl` → файл содержит `<mermaid>` и `</mermaid>`, отсутствует fenced block. Поведение SVG-файла через `mermaid_save` MCP не тестируется в shell-тесте (MCP-вызов — LLM-уровень). Тест покрывает shell-артефакт полностью. |
| AC-002 | mermaid flowchart + syntax:Markdown → в md вставляется fenced \`\`\`mermaid...\`\`\` | `SKILL.md:Mermaid-путь/Генерация и вставка`; `insert_diagram_ref.sh:строки 87-92 (SYNTAX!=XML → fenced block)` | `ac-003-mermaid-fenced.sh` | ✅ | Тест проверяет: `insert_diagram_ref.sh --syntax Markdown --mermaid-dsl` → в md есть ` ```mermaid`, DSL-контент, и минимум 2 тройных бэктика. Семантически корректно. |
| AC-003 | gitGraph/journey/requirementDiagram/C4Context → stdout `[WARN]` с именем типа + альтернативой, файлы не создаются, exit 0 | `validate_diagram_type.sh:строки 82-84`; `SKILL.md:Mermaid-путь/Неподдерживаемые типы` | `ac-008-unsupported-mermaid.sh` | ✅ | Тест перебирает все 4 неподдерживаемых типа из FR-005 и проверяет: `[WARN]` в stdout, имя типа в stdout, рекомендация `flowchart` или `drawio`, exit 0. Все 4 типа явно заявлены в скрипте `UNSUPPORTED_TYPES`. Тест также проверяет обратное: 8 поддерживаемых типов не вызывают `[WARN]`. Семантически полное покрытие. |
| AC-004 | drawio → создаются `<name>.drawio` и `<name>.svg`; `<name>.svg` содержит `content=` (embedded XML) | `save_diagram.sh:строки 94-98 (атомарная запись .drawio)`; `drawio_convert.py (конвертация в SVG с content=)` | `ac-005-drawio-roundtrip.sh` | ✅ | Тест вызывает `drawio_convert.py` напрямую с минимальным валидным mxfile XML. Проверяет: exit 0, `.svg` создан, `.svg` содержит `content=`, `.svg` содержит `<svg`, `.drawio` сохранён. Условие spec "grep -c 'content=' возвращает 1" проверено через `assert_grep`. Семантически полное. |
| AC-005 | drawio + syntax:XML → в md вставляется `<Image src="<name>.svg" />` | `insert_diagram_ref.sh:строки 95-102 (SVG_NAME + SYNTAX=XML → <Image>)` | `ac-010-md-insert.sh` | ✅ | Тест вызывает `insert_diagram_ref.sh --syntax XML --svg-name deploy.svg --alt "Deploy diagram"`. Проверяет: в md есть `<Image src="deploy.svg"` и `/>`. Дополнительно проверяет Markdown-синтаксис и сохранность существующего контента страницы. Семантически корректно. |
| AC-006 | `.doc-root.yaml` отсутствует → stdout `[WARN]` про отсутствие, Markdown-синтаксис по умолчанию, выполнение не прерывается | `SKILL.md:Определение синтаксиса каталога (exit_code≠0 → echo [WARN], SYNTAX=Markdown)`; `find_doc_root.sh:exit 1 при не найденном файле` | `ac-006-fallback-noyaml.sh` | ⚠️ | Тест проверяет: `find_doc_root.sh` возвращает exit 1 при отсутствии `.doc-root.yaml`, и Python-однострочник возвращает `Markdown` при пустом контенте. **Проблема:** `[WARN]` в stdout — это поведение SKILL.md-промпта (LLM выводит на основе exit code), а не shell-скрипта. Тест не ассертирует наличие строки `[WARN]` в stdout (что технически корректно для shell-уровня), но AC говорит «в stdout появляется [WARN]». Для shell-тестируемой части (find → exit 1, парсер → Markdown) покрытие полное. Поведение `[WARN]`-вывода — на уровне LLM-промпта, что не поддаётся shell-тестированию. |
| AC-007 | кириллица в имени файла → итоговое имя ASCII (через `slugify.py`), в stdout отображается преобразованное имя | `slugify.py (уже существовал)`; `SKILL.md:Генерация slug (вывод сообщи пользователю)` | `ac-007-slugify.sh` | ⚠️ | Тест проверяет: `slugify.py` возвращает ASCII-slug (exit 0, непустой, нет байтов > 127), Latin → без изменений, смешанный → ASCII, пустой ввод → exit 2 со словом `empty` в stderr. **Проблема:** AC говорит «в stdout отображается преобразованное имя» — это поведение SKILL.md-промпта (LLM пишет «Имя файла: ... → ...»), не shell-скрипта. Сам `slugify.py` не выводит оригинал + преобразованный. Тест покрывает скрипт полностью; вывод сравнения — LLM-уровень, shell-нетестируем. |
| AC-008 | MCP mermaid (`claude-mermaid`) недоступен → stdout: сгенерированный DSL + инструкция по ручному сохранению; `.svg` не создаётся; exit 0 | `SKILL.md:Mermaid-путь/MCP-недоступность (AC-008)` | **Нет отдельного shell-теста** | ⚠️ | AC-008 реализован в SKILL.md как LLM-инструкция: «если `mermaid_save` MCP недоступен — вывести DSL и инструкцию». Shell-скрипт для этого AC не создан (нельзя протестировать MCP-недоступность в shell без mock MCP). QA-отчёт не включает AC-008 в таблицу отдельной строкой. Поведение задокументировано в SKILL.md корректно; отсутствие shell-теста — структурная пробел, приемлемый для LLM-уровня поведения. |
| AC-009 | MCP drawio недоступен → `.drawio` сохраняется, `.svg` не создаётся; stderr `[ERROR]` с командой ручной конвертации; exit 1 | `save_diagram.sh:строки 101-107 (MCP_STATUS=disabled → stderr [ERROR] + exit 1)` | `ac-009-mcp-fallback.sh` | ✅ | Тест вызывает `save_diagram.sh` с `DIAGRAM_DRAWIO_MCP=disabled`. Проверяет: exit 1, `.drawio` существует, `.svg` не существует, stderr содержит `[ERROR]` и `drawio_convert.py`. Все 4 условия AC-009 ассертированы явно. Семантически полное покрытие. |
| AC-010 | файл с указанным именем уже существует → stdout `[WARN]` с путём к файлу; перезапись не выполняется без подтверждения | `save_diagram.sh:строки 74-78 (FORCE=0 + файл существует → [WARN] + exit 0)` | `ac-011-no-overwrite.sh` | ✅ | Тест: вызов без `--force` → exit 0, stdout содержит `[WARN]` и `existing.drawio`, оригинальный контент `.drawio` не изменён. Второй test-case: с `--force` → exit 0, файл перезаписан. Семантически полное покрытие. |
| AC-011 | отсутствует `target_page` → skill переспрашивает пользователя, файлы не создаются | `SKILL.md:Обязательные параметры (target_page — если не указан → переспроси, не создавай файлы)` | **Нет отдельного shell-теста** | ⚠️ | AC-011 — поведение LLM-промпта: skill переспрашивает через диалог. Shell-тест для этого не создан и не создаётся (поведение не детерминировано shell-командой). В SKILL.md явно прописано: «если не указан — переспроси». Отсутствие shell-теста приемлемо; AC выполним только через интеграционный тест с реальным LLM. |
| AC-012 | созданный `.drawio` — валидный XML; `python3 -c "import xml.etree.ElementTree as ET; ET.parse('<name>.drawio')"` → exit 0 | `save_diagram.sh:строки 81-88 (ET.fromstring валидация перед записью)`; `drawio_convert.py (принимает только валидный mxfile)` | `ac-012-invalid-xml.sh` | ✅ | Тест: пустой файл → exit ≠ 0 (нет SVG), не-XML → exit ≠ 0, XML без `<diagram>` → exit ≠ 0, XML без `<mxGraphModel>` → exit ≠ 0. И позитив: валидный mxfile → `ET.parse` exit 0. Не-XML → `ET.parse` exit ≠ 0. Семантически полное покрытие обеих сторон контракта. |

---

## Детальный разбор ⚠️ случаев

### AC-006 — [WARN] в stdout при отсутствии .doc-root.yaml

**Что делает тест:** проверяет, что `find_doc_root.sh` возвращает exit 1 и Python-однострочник возвращает `Markdown`. Это корректная проверка shell-части инфраструктуры.

**Что не проверяет тест:** сам вывод строки `[WARN] .doc-root.yaml не найден. Используется синтаксис Markdown по умолчанию.` — это ответственность SKILL.md-промпта. LLM должна вывести это сообщение на основе exit code. Shell-тест не может валидировать LLM-вывод.

**Оценка:** shell-тест семантически полный для своей области. Поведение `[WARN]`-строки зафиксировано в SKILL.md как инструкция. Приемлемо.

### AC-007 — «в stdout отображается преобразованное имя»

**Что делает тест:** проверяет корректность транслитерации через `slugify.py` (ASCII-only output, непустой результат, boundary cases). Это полная проверка скрипта.

**Что не проверяет тест:** что в финальном stdout сессии Claude Code пользователь видит сравнение «оригинальное имя → slug». Это SKILL.md-инструкция («Сообщи пользователю преобразованное имя»), не выход скрипта.

**Оценка:** shell-тест полный. LLM-уровневый вывод не тестируем в shell. Приемлемо.

### AC-008 — MCP mermaid недоступен (поведение целиком на LLM-уровне)

**Что есть:** SKILL.md прописывает раздел «MCP-недоступность (AC-008)» с явной инструкцией: вывести DSL в stdout, инструкцию по ручному сохранению, не создавать `.svg`, exit 0. ADR-0004 подтверждает, что оба сценария (`mermaid_save` с path или без) описаны в SKILL.md.

**Что нет:** shell-теста, симулирующего недоступный MCP mermaid. Создание такого теста требует mock-инфраструктуры MCP-сервера, что вне скоупа shell-тестирования.

**Оценка:** структурная пробел, но не блокер — поведение задокументировано в SKILL.md и верифицируется только через интеграционный тест с реальным Claude Code + MCP. Фиксируем как known gap.

### AC-011 — LLM переспрашивает при отсутствии target_page

**Что есть:** SKILL.md явно: «если не указан — переспроси, не создавай файлы». Shell-скрипты не создают файлы без явных аргументов (все `--output-*` обязательны, проверяются через валидацию параметров).

**Что нет:** shell-теста, воспроизводящего диалог «нет target_page → переспрос». Нельзя тестировать shell-командой.

**Оценка:** приемлемо. Инфраструктурная защита (скрипты требуют параметры) в наличии.

---

## Open questions из spec — статус

| OQ | Вопрос из spec | Резолвинг ADR | Статус |
|----|----------------|---------------|--------|
| OQ-1 | Split плагина: один skill или два плагина (`diagram-mermaid` / `diagram-drawio`)? | ADR-0001: один skill `diagram-on-demand` внутри `gramax` | ✅ resolved |
| OQ-2 | Drawio MCP-выбор: какой из трёх бэкендов? | ADR-0002: `lgazo/drawio-mcp-server` как опциональный; MVP через `drawio_convert.py`; ADR-0003: vendoring = только документация + `mcpServers` в plugin.json | ✅ resolved |
| OQ-3 | Сигнатура `mermaid_save`: принимает path напрямую или только preview? | ADR-0004 и ADR-0005: оба сценария описаны в SKILL.md; Dev проверяет PoC; MVP реализует оба пути в промпте | ✅ resolved (с оговоркой: PoC Dev-задача, не MVP-блокер) |
| OQ-4 | Drawio MCP: генерирует SVG из описания или только конвертирует готовый XML? | ADR-0002: LLM генерирует mxfile XML, `drawio_convert.py` конвертирует в SVG с embedded XML; MCP — опциональный рендер-бэкенд | ✅ resolved |
| OQ-5 | Атомарность записи: temp-файл + rename или удаление недосозданного? | ADR-0005 раздел 4: temp+rename (POSIX-атомарность); `save_diagram.sh` реализует точно по ADR | ✅ resolved, реализован |
| OQ-6 | Позиция вставки ссылки в md: конец файла или угадывание? | ADR-0005 раздел 6 + ADR-0004: по умолчанию в конец файла (bash append); целевая вставка — LLM-инструкция; ADR-0007: shell-парсер H2/H3 — Phase 2 | ✅ resolved |

Все 6 открытых вопросов закрыты в ADR. Cross-check выполнен.

---

## Out-of-scope verification

Проверка: не просочились ли Phase 2 элементы в MVP-реализацию.

| Элемент из Out of Scope | MVP-реализация | Вердикт |
|-------------------------|----------------|---------|
| Auto-detection движка | Не реализован. SKILL.md: «если `engine` не указан — переспроси». ADR-0004: auto-detect явно out-of-scope. | ✅ не просочился |
| Генерация drawio XML с нуля без MCP-рендера (только `drawio_convert.py`) | MVP делает ровно это: LLM генерирует mxfile XML, `save_diagram.sh` вызывает `drawio_convert.py`. Результат — SVG с embedded XML (не визуальный рендер). ADR-0002 и ADR-0007 явно фиксируют ограничение. | ✅ соответствует ADR-0002 |
| Редактирование существующей SVG через skill (`edit` команда) | Не реализован. `save_diagram.sh` поддерживает только создание (`--force` — перезапись, не редактирование). | ✅ не просочился |
| Live-preview в браузере | Не реализован. SKILL.md не содержит упоминания `mermaid_preview`. ADR-0007 фиксирует как Phase 2. | ✅ не просочился |
| Batch-генерация нескольких диаграмм | Не реализован. Один вызов = одна операция. | ✅ не просочился |
| GitGraph, journey, requirementDiagram, C4Context | Не реализованы. `validate_diagram_type.sh` выводит `[WARN]` и завершается — не создаёт файлы. | ✅ соответствует FR-005 |
| Полный визуальный SVG-рендер (с геометрией) | Не реализован. `drawio_convert.py` создаёт SVG с embedded XML, без визуальной геометрии. ADR-0007 явно: Phase 2 (PoC `lgazo/drawio-mcp-server`). | ✅ не просочился |

---

## Verdict

**Accepted** — с документированием known gaps.

Все 12 AC из spec покрыты по существу:
- 8 из 12 AC покрыты shell-тестами с полным семантическим ассертингом (AC-001, AC-002, AC-003, AC-004, AC-005, AC-009, AC-010, AC-012).
- 2 из 12 AC (AC-006, AC-007) покрыты shell-тестами частично: shell-уровень полный, LLM-уровневый вывод (`[WARN]`-строка, сравнение имён) задокументирован в SKILL.md как инструкция и не поддаётся shell-тестированию.
- 2 из 12 AC (AC-008, AC-011) реализованы на уровне SKILL.md-инструкций и не тестируемы в shell — это known gap, приемлемый для behavior, зависящего от LLM-диалога.

Все 6 открытых вопросов закрыты в ADR. Все Phase 2 элементы не просочились в MVP. QA-отчёт зелёный (12/12, Exit=0).

**Нумерационное несоответствие тест-файлов и spec-AC** — задокументировано в данном отчёте. Рекомендуется в следующей итерации выравнивать нумерацию тестов с нумерацией spec-AC.

---

## Рекомендации Tech-writer

1. **README плагина `plugins/gramax/README.md`** — добавить раздел `diagram-on-demand` с описанием триггеров: «нарисуй mermaid», «сделай drawio-схему», «добавь диаграмму». Явно указать ограничение drawio SVG для MVP: «SVG содержит embedded XML для редактирования в diagrams.net; визуальный рендер — при открытии в браузере».

2. **CHANGELOG плагина `plugins/gramax/CHANGELOG.md`** — bump до 1.3.0 (minor, additive фича). Текущая версия в QA-отчёте: 1.2.0. По ADR-0006: minor bump при добавлении нового skill.

3. **`plugins/gramax/.claude-plugin/plugin.json`** — версия должна быть обновлена с 1.2.0 до 1.3.0 (ADR-0006). QA-отчёт фиксирует текущую версию 1.2.0.

4. **`.claude-plugin/marketplace.json`** — bump `metadata.version` с 1.0.0 до 1.1.0 (ADR-0006: minor bump при additive изменении). Description entry `gramax` — обновить для упоминания skill `diagram-on-demand`.

5. **Новый entry в marketplace.json** — не добавлять (ADR-0001: split отклонён; один плагин `gramax`).

6. **README раздел «Drawio MCP (опционально)»** — добавить инструкцию установки `@lgazo/drawio-mcp-server@2.1.0` (ADR-0003). Без этого раздела пользователи не узнают о возможности расширенного рендеринга.

7. **Known gap для документации** — в README или SKILL.md можно добавить явное примечание: поведение при недоступном MCP mermaid (AC-008) и поведение при отсутствии `target_page` (AC-011) — LLM-диалоговые сценарии, не покрытые shell-тестами; верифицируются интеграционным тестом с Claude Code.
