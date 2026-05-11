# Diagram On Demand — TDD Test Stubs

Smoke-тесты для фичи `diagram-on-demand` плагина `gramax`.

## TDD-фаза

Эти тесты написаны **до реализации** (QA-author → Dev цикл).

**Текущий ожидаемый результат: все тесты падают.** Это нормально и ожидаемо на этапе TDD-stubs.

Dev делает тесты зелёными по одному, реализуя контракты из spec и ADR.

## Как запускать

```bash
# Все 12 тестов
bash tests/gramax/diagram-on-demand/run.sh

# Отдельный тест
bash tests/gramax/diagram-on-demand/ac-005-drawio-roundtrip.sh
```

## Как интерпретировать результаты

### Failing stub (ожидаемое до реализации)

```
==> ac-001-skill-exists.sh
TODO: AC-001 — plugins/gramax/skills/diagram-on-demand/SKILL.md должен существовать
FAIL: ac-001-skill-exists — 1 assertion(s) failed
```

Сообщение вида `TODO: AC-NNN — ...` означает: Dev ещё не создал этот артефакт. Это красная фаза TDD.

### Синтаксическая ошибка (недопустимо)

```
ac-001-skill-exists.sh: line 12: syntax error
```

Такие ошибки — признак сломанного stub-файла. Нужно починить тест, не реализацию.

### Прошедший тест (зелёная фаза)

```
==> ac-005-drawio-roundtrip.sh
OK: ac-005-drawio-roundtrip
```

После реализации все 12 тестов должны показывать `OK`.

## Покрытие AC

| Файл | AC из spec | Что проверяется |
|------|-----------|-----------------|
| `ac-001-skill-exists.sh` | AC-001 (по spec-нумерации) | SKILL.md создан, frontmatter валидный |
| `ac-002-find-doc-root.sh` | FR-003, FR-006, AC-006 | find_doc_root.sh: обход вверх, exit 1 при отсутствии |
| `ac-003-mermaid-fenced.sh` | AC-002 | Markdown-syntax → fenced ```mermaid блок |
| `ac-004-mermaid-xml.sh` | AC-001 | XML-syntax → `<mermaid>` теги |
| `ac-005-drawio-roundtrip.sh` | AC-004 | drawio_convert.py: .drawio → .svg с content= |
| `ac-006-fallback-noyaml.sh` | AC-006, FR-006 | нет .doc-root.yaml → Markdown fallback, [WARN] |
| `ac-007-slugify.sh` | AC-007, FR-008 | slugify.py: кириллица → ASCII, empty → exit 2 |
| `ac-008-unsupported-mermaid.sh` | AC-003, FR-005 | gitGraph/journey → [WARN], exit 0, файлы не создаются |
| `ac-009-mcp-fallback.sh` | AC-009, FR-011 | MCP disabled → .drawio есть, .svg нет, stderr [ERROR], exit 1 |
| `ac-010-md-insert.sh` | AC-005, FR-003, FR-004 | insert_diagram_ref.sh: XML и Markdown форматы |
| `ac-011-no-overwrite.sh` | AC-010, FR-007 | существующий файл → [WARN], без перезаписи; --force разрешает |
| `ac-012-invalid-xml.sh` | AC-012, FR-009 | drawio_convert.py: невалидный XML → exit != 0, нет .svg |

## Зависимости тестов

Тесты **не** требуют внешних инструментов кроме `bash` и `python3` (stdlib).

Тесты **не** вызывают MCP-серверы и **не** симулируют LLM. Проверяются только:
- файловые артефакты (существование, содержимое)
- exit codes скриптов
- stdout/stderr контент через grep

## Структура каталога

```
tests/gramax/diagram-on-demand/
├── run.sh                    # entry point
├── README.md                 # этот файл
├── lib/
│   └── assert.sh             # assert_file_exists, assert_grep, assert_exit_code, ...
├── fixtures/
│   ├── xml-syntax/
│   │   └── .doc-root.yaml    # syntax: XML
│   └── md-syntax/
│       └── .doc-root.yaml    # syntax: Markdown
├── ac-001-skill-exists.sh
├── ac-002-find-doc-root.sh
├── ac-003-mermaid-fenced.sh
├── ac-004-mermaid-xml.sh
├── ac-005-drawio-roundtrip.sh
├── ac-006-fallback-noyaml.sh
├── ac-007-slugify.sh
├── ac-008-unsupported-mermaid.sh
├── ac-009-mcp-fallback.sh
├── ac-010-md-insert.sh
├── ac-011-no-overwrite.sh
└── ac-012-invalid-xml.sh
```

## Связанные документы

- Spec: `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md`
- ADR-0001: `docs/adr/0001-diagram-on-demand-plugin-split.md`
- ADR-0005: `docs/adr/0005-save-flow-script-api-contract.md`
