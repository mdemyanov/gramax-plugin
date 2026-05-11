---
title: diagram-on-demand
name: diagram-on-demand
description: Генерирует диаграмму по описанию и вставляет её в Gramax-страницу. Используй когда пользователь говорит «нарисуй mermaid», «сделай drawio-схему», «добавь диаграмму», «создай mermaid-диаграмму», «нарисуй flowchart», «нарисуй sequenceDiagram». Не для просмотра существующих диаграмм.
triggers:
  - "нарисуй mermaid"
  - "сделай drawio"
  - "добавь диаграмму"
  - "создай mermaid-диаграмму"
  - "нарисуй drawio-схему"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

# Diagram on Demand

Skill для генерации диаграмм (mermaid или drawio) по описанию и вставки в Gramax-каталог.

## Обязательные параметры

Перед началом убедись, что у тебя есть:
1. **engine** — `mermaid` или `drawio` (явный выбор пользователя; если не указан — переспроси)
2. **description** — словесное описание диаграммы (если пустое — переспроси)
3. **target_page** — путь к `.md`-файлу, рядом с которым сохраняется диаграмма (если не указан — переспроси, не создавай файлы)

Опциональные:
- **diagram_name** — имя файла без расширения (по умолчанию — slug из первых 4 слов description)
- **diagram_type** — тип mermaid (для engine=mermaid; выбирай по смыслу description)

## Определение синтаксиса каталога

```bash
# Найти .doc-root.yaml вверх по дереву от target_page
doc_root=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/find_doc_root.sh" "<target_page>")
exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo "[WARN] .doc-root.yaml не найден. Используется синтаксис Markdown по умолчанию."
  SYNTAX="Markdown"
else
  SYNTAX=$(python3 -c "
import re, sys
content = open(sys.argv[1]).read()
m = re.search(r'^syntax:\s*(\S+)', content, re.MULTILINE)
print(m.group(1) if m else 'Markdown')
" "$doc_root")
fi
```

## Генерация slug для имени файла

```bash
slug=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.py" "<diagram_name_or_description_prefix>")
```

Кириллица в именах файлов транслитерируется автоматически. Сообщи пользователю преобразованное имя.

## Mermaid-путь

### Поддерживаемые типы

`flowchart`, `sequenceDiagram`, `gantt`, `classDiagram`, `stateDiagram-v2`, `erDiagram`, `pie`, `mindmap`

### Неподдерживаемые типы (FR-005)

`gitGraph`, `journey`, `requirementDiagram`, `C4Context`

При запросе неподдерживаемого типа:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate_diagram_type.sh" "<diagram_type>"
```
Если скрипт выводит `[WARN]` — вывести предупреждение пользователю, не создавать файлы, exit 0.

### Генерация и вставка

1. Сгенерируй mermaid DSL одного из поддерживаемых типов
2. Вставь в md-файл:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/insert_diagram_ref.sh" \
  --target "<target_page>" \
  --syntax "<SYNTAX>" \
  --mermaid-dsl "<generated_dsl>"
```

Формат вставки зависит от SYNTAX:
- `XML` → `<mermaid>...</mermaid>`
- `Markdown` → фenced ` ```mermaid...``` `

### MCP-недоступность (AC-008)

Если `mermaid_save` MCP недоступен — вывести в stdout сгенерированный DSL и инструкцию по ручному сохранению. `.svg` не создавать. Exit code 0.

## Drawio-путь

1. Сгенерируй валидный mxfile XML (см. `references/drawio-llm-template.md`)
2. Сохрани `.drawio` и конвертируй в `.svg`:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/save_diagram.sh" \
  --xml "<mxfile_xml_content>" \
  --output-drawio "<target_dir>/<slug>.drawio" \
  --output-svg "<target_dir>/<slug>.svg"
```

3. Вставь ссылку в md:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/insert_diagram_ref.sh" \
  --target "<target_page>" \
  --syntax "<SYNTAX>" \
  --svg-name "<slug>.svg" \
  --alt "<description_prefix>"
```

### Конфликт файлов (FR-007, AC-010)

Если `save_diagram.sh` выводит `[WARN]` и завершается с exit 0 — сообщи пользователю и спроси подтверждение перед повторным вызовом с `--force`.

### MCP-недоступность (AC-009)

Если `DIAGRAM_DRAWIO_MCP=disabled` — `.drawio` сохраняется, `.svg` не создаётся, в stderr появляется `[ERROR]` с командой ручной конвертации. Exit code 1.

## Формат вывода

- Успех: `Created: <path>` + вставленный фрагмент md
- Предупреждение: `[WARN] <текст>` в stdout
- Ошибка: `[ERROR] <текст>` в stderr, exit code != 0

## Детали

Подробные шаблоны drawio XML и примеры: `references/drawio-llm-template.md`
