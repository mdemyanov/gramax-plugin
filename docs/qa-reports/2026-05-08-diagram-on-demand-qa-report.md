# QA Report: diagram-on-demand

**Дата:** 2026-05-08
**Worktree:** feat-diagram-on-demand
**Commit baseline:** a090311
**QA-runner:** automated

## Сводка

| Категория | Статус |
|-----------|--------|
| Smoke (12 AC) | PASS — 12/12 passed |
| Regression Python | PASS — 7/7 passed |
| check.sh --fast | PASS |
| Манифесты JSON | PASS |
| Submodule integrity | PASS |
| Edge cases | PASS (4/4) |

## Manifest validation

- `.claude-plugin/marketplace.json`: OK — валидный JSON, содержит плагины `gramax` и `claude-mermaid`.
- `plugins/gramax/.claude-plugin/plugin.json`: OK — валидный JSON, version 1.2.0.
- Объявленные skill-артефакты существуют:
  - `plugins/gramax/skills/diagram-on-demand/SKILL.md`: OK
  - `plugins/gramax/skills/diagrams/SKILL.md`: OK
  - `plugins/gramax/skills/comments-write/SKILL.md`: OK
  - `plugins/gramax/skills/comments-read/SKILL.md`: OK
  - `plugins/gramax/skills/writer/SKILL.md`: OK
- `plugins/gramax/commands/`: каталог отсутствует — в plugin.json команды не объявлены (только skills и agents). Расхождение отсутствует.
- Shell-скрипты исполняемые (`-rwxr-xr-x`):
  - `find_doc_root.sh`, `validate_diagram_type.sh`, `save_diagram.sh`, `insert_diagram_ref.sh` — все 4 OK.
- Submodule `plugins/claude-mermaid`: без модификационного маркера (`+`/`-`), hash `817759b9b79eec7e365b9c18b5b14d870ef3ea9c`. Integrity OK.

## Regression analysis

Новые скрипты (`find_doc_root.sh`, `validate_diagram_type.sh`, `save_diagram.sh`, `insert_diagram_ref.sh`) и skill (`diagram-on-demand/SKILL.md`) — добавлены в этой ветке, до этого не существовали.

Существующие артефакты, которые не должны были сломаться:
- `drawio_convert.py`, `slugify.py`, `gen_comment_id.py`, `parse_comments.py`, `validate_comments.py`, `validate_structure.py` — не изменялись.
- Python-тесты `plugins/gramax/scripts/tests/test_validate_structure.py` — 7/7 OK (Ran 7 tests in 0.624s).
- `plugins/gramax/skills/diagrams/SKILL.md` — не изменялся.
- `plugins/claude-mermaid/` — submodule не тронут.

Регрессий не обнаружено.

## Smoke tests (детали)

Команда: `bash tests/gramax/diagram-on-demand/run.sh`
Результат: `passed=12 failed=0` / EXIT=0

```
==> ac-001-skill-exists.sh        OK: ac-001-skill-exists
==> ac-002-find-doc-root.sh       OK: ac-002-find-doc-root
==> ac-003-mermaid-fenced.sh      OK: ac-003-mermaid-fenced
==> ac-004-mermaid-xml.sh         OK: ac-004-mermaid-xml
==> ac-005-drawio-roundtrip.sh    OK: ac-005-drawio-roundtrip
==> ac-006-fallback-noyaml.sh     OK: ac-006-fallback-noyaml
==> ac-007-slugify.sh             OK: ac-007-slugify
==> ac-008-unsupported-mermaid.sh OK: ac-008-unsupported-mermaid
==> ac-009-mcp-fallback.sh        OK: ac-009-mcp-fallback
==> ac-010-md-insert.sh           OK: ac-010-md-insert
==> ac-011-no-overwrite.sh        OK: ac-011-no-overwrite
==> ac-012-invalid-xml.sh         OK: ac-012-invalid-xml
============================================
Results: passed=12 failed=0
============================================
```

## Regression Python (детали)

Команда: `python3 -m unittest discover -s plugins/gramax/scripts/tests/ -v`
Результат: `Ran 7 tests in 0.624s` / OK / EXIT=0

```
test_exits_nonzero (test_validate_structure.BadCatalogTests)           ... ok
test_v1_orphan_section (test_validate_structure.BadCatalogTests)       ... ok
test_v2_index_with_properties (test_validate_structure.BadCatalogTests)... ok
test_v3_flat_notation (test_validate_structure.BadCatalogTests)        ... ok
test_v4_invalid_property (test_validate_structure.BadCatalogTests)     ... ok
test_v5_invalid_value (test_validate_structure.BadCatalogTests)        ... ok
test_good_catalog_passes (test_validate_structure.GoodCatalogTests)    ... ok
```

## Edge cases (детали)

### Кириллица (slugify.py)

```
$ python3 plugins/gramax/scripts/slugify.py "Поток входа пользователя"
potok-vkhoda-polzovatelya
```

Результат: `potok-vkhoda-polzovatelya` — валидный latin-slug. PASS.

### drawio_convert.py roundtrip

Вызов с минимальным валидным mxfile XML, выходной SVG-файл проверен на наличие `content=` атрибута и тега `<svg>`.

```
exit_code=0
content= — найдено (grep count: 1)
<svg — найдено (grep count: 1)
```

PASS.

### find_doc_root.sh traversal

Создан `tmpdir/.doc-root.yaml`, запрос из `tmpdir/sub/deep` (позиционный аргумент — скрипт не поддерживает флаг `--from`):

```
$ bash find_doc_root.sh "$TMPDIR/sub/deep"
/var/folders/.../tmp.xxx/.doc-root.yaml
exit_code=0
```

PASS. Примечание: edge-case spec в задании указывал `--from`, но скрипт принимает только позиционный аргумент. Контрактный тест ac-002 (который тестирует реальный API) прошёл успешно. Расхождение — в описании задания, не в реализации.

### save_diagram.sh с DIAGRAM_DRAWIO_MCP=disabled

```
exit_code=1
drawio exists: YES
svg exists: NO
stderr:
  [ERROR] MCP drawio-бэкенд недоступен. deploy.drawio сохранён.
  [ERROR] Для ручной конвертации: python3 .../drawio_convert.py .../deploy.drawio .../deploy.svg
```

Все условия AC-009 выполнены: exit 1, `.drawio` создан, `.svg` отсутствует, stderr содержит `[ERROR]` и `drawio_convert.py`. PASS.

## Failed tests (детали)

Упавших тестов нет.

| Test | Reason category | Probable cause | Action |
|------|-----------------|----------------|--------|
| — | — | — | — |

## AC coverage check

| AC | Тест | Статус |
|----|------|--------|
| AC-001 (skill SKILL.md существует) | ac-001-skill-exists.sh | PASS |
| AC-002 (find_doc_root.sh contract) | ac-002-find-doc-root.sh | PASS |
| AC-003 (mermaid fenced-блок, Markdown syntax) | ac-003-mermaid-fenced.sh | PASS |
| AC-004 (mermaid XML-тег, XML syntax) | ac-004-mermaid-xml.sh | PASS |
| AC-005 (drawio roundtrip: .drawio + .svg с content=) | ac-005-drawio-roundtrip.sh | PASS |
| AC-006 (fallback без .doc-root.yaml → Markdown) | ac-006-fallback-noyaml.sh | PASS |
| AC-007 (кириллица в slugify → latin-slug) | ac-007-slugify.sh | PASS |
| AC-008 (неподдерживаемый mermaid-тип → предупреждение) | ac-008-unsupported-mermaid.sh | PASS |
| AC-009 (MCP disabled → .drawio есть, .svg нет, [ERROR] stderr) | ac-009-mcp-fallback.sh | PASS |
| AC-010 (вставка ссылки в md-файл) | ac-010-md-insert.sh | PASS |
| AC-011 (no-overwrite: существующий файл не перезаписывается) | ac-011-no-overwrite.sh | PASS |
| AC-012 (невалидный XML → [ERROR], exit 1) | ac-012-invalid-xml.sh | PASS |

## Рекомендация

- [x] merge / готов к Tech-writer фазе
- [ ] block + назад в Dev
- [ ] re-run (flaky)

**Обоснование:** Все 12 smoke-тестов прошли (EXIT=0). 7 Python regression-тестов прошли (EXIT=0). check.sh --fast прошёл. Оба JSON-манифеста валидны. Все 4 shell-скрипта исполняемые. Submodule не тронут. 4/4 edge-cases прошли. Регрессий нет. Блокеров нет.

**Наблюдение для команды:** В описании edge-case задания QA-runner был указан несуществующий флаг `--from` для `find_doc_root.sh`. Скрипт принимает только позиционный аргумент. Фактический API задокументирован в самом скрипте (Usage-строка). Рекомендуется обновить шаблон edge-case задания для QA-runner.
