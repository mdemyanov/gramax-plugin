# ADR-0005: Контракт API save flow (drawio_convert.py, slugify.py, .doc-root.yaml)

**Status:** Superseded by ADR-0008
**Date:** 2026-05-08
**Plugin:** gramax

## Context

Spec open questions #5 (атомарность записи) и #6 (позиция вставки). Skill должен:
1. Найти `.doc-root.yaml` (обход вверх от `target_page`).
2. Прочитать `syntax` → выбрать формат ссылки.
3. Сгенерировать slug для имени файла.
4. Записать `.drawio` / `.svg` атомарно.
5. Вставить ссылку в md.

Нужно зафиксировать точный вызывающий контракт между skill-промптом и скриптами, чтобы Dev реализовал без неопределённости.

## Decision

### 1. Поиск `.doc-root.yaml`

Skill описывает алгоритм обхода вверх в промпте. Реализация — в bash-части skill или в новом `find_doc_root.sh`:

```bash
find_doc_root() {
  local dir
  dir="$(dirname "$(realpath "$1")")"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.doc-root.yaml" ]]; then
      echo "$dir/.doc-root.yaml"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}
```

При отсутствии `.doc-root.yaml` (return 1) — использовать `Markdown` как дефолт + вывести `[WARN]` (FR-006, AC-006).

Чтение `syntax` из YAML: Python-однострочник (stdlib, без pyyaml):
```bash
syntax=$(python3 -c "
import re, sys
content = open(sys.argv[1]).read()
m = re.search(r'^syntax:\s*(\S+)', content, re.MULTILINE)
print(m.group(1) if m else 'Markdown')
" "$doc_root_path")
```

### 2. Slugify для имени файла

Вызов уже существующего скрипта:

```bash
slug=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.py" "$diagram_name_or_description_prefix")
```

`slugify.py` принимает произвольную строку, возвращает ASCII-slug. При пустом вводе — exit 2 (FR-008, AC-007).

Алгоритм выбора `diagram_name`:
- Если пользователь передал `diagram_name` — используем его как вход `slugify.py`.
- Иначе — берём первые 4 слова из `description`.

### 3. Проверка существующего файла

До записи:
```bash
target_drawio="${target_dir}/${slug}.drawio"
target_svg="${target_dir}/${slug}.svg"

if [[ -f "$target_drawio" || -f "$target_svg" ]]; then
  echo "[WARN] Файл ${target_drawio} уже существует. Перезаписать? (y/n)"
  read -r confirm
  [[ "$confirm" != "y" ]] && exit 0
fi
```

FR-007, AC-010: не перезаписывать без подтверждения.

### 4. Атомарная запись (open question #5)

Решение: temp-файл + rename (атомарный на Linux/macOS, POSIX-гарантия).

Для drawio-пути:

```bash
# Шаг 1: сохранить .drawio через temp
tmp_drawio=$(mktemp "${target_dir}/.tmp_XXXXXX.drawio")
printf '%s' "$mxfile_xml" > "$tmp_drawio"
mv "$tmp_drawio" "$target_drawio"

# Шаг 2: конвертация в SVG
tmp_svg=$(mktemp "${target_dir}/.tmp_XXXXXX.svg")
if python3 "${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py" "$target_drawio" "$tmp_svg"; then
  mv "$tmp_svg" "$target_svg"
else
  rm -f "$tmp_svg"
  echo "[ERROR] drawio_convert.py завершился с ошибкой. ${target_drawio} сохранён." >&2
  echo "[ERROR] Для ручной конвертации: python3 ${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py ${target_drawio} ${target_svg}" >&2
  exit 1
fi
```

При ошибке конвертации: `.drawio` сохранён, `.svg` не создан, exit 1 (FR-011, AC-009, NFR-005).

### 5. Вызов drawio_convert.py

Сигнатура (существующая):
```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/drawio_convert.py" <input.drawio> <output.svg>
```

`drawio_convert.py` возвращает exit code 1 при ошибке (OSError, ValueError, ParseError).

Skill не передаёт `--width` / `--height` — используются значения `pageWidth`/`pageHeight` из XML, или дефолт 800×600.

### 6. Вставка ссылки в md (open question #6)

**По умолчанию: в конец файла.** Добавляем пустую строку + ссылку.

Формат для `syntax: XML`:
```xml
<Image src="${slug}.svg" alt="${description_prefix}" />
```

Формат для `syntax: Markdown`:
```markdown
![${description_prefix}](${slug}.svg)
```

Skill-промпт должен описывать: если пользователь указал контекст вставки («после раздела Архитектура»), Claude выполняет целевую вставку самостоятельно (как LLM-задача редактирования файла), не через bash.

Bash-скрипт обрабатывает только дефолтный случай (append). Целевая вставка — LLM-инструкция в SKILL.md.

### 7. Mermaid-путь: запись файла

Если `mermaid_save(path, dsl_content)` доступен — вызываем через MCP:
```
mermaid_save(path="${target_dir}/${slug}.svg", content="${mermaid_dsl}")
```

Если `mermaid_save` недоступен или не принимает path (AC-008): выводим DSL в stdout + инструкцию. SVG не создаём. Exit code 0.

Dev обязан проверить сигнатуру `mermaid_save` в PoC (claude-mermaid plugin.json или MCP tool list). Если tool принимает только preview — реализовать fallback-ветку записи файла (python3 write или bash redirect).

### Итоговая таблица вызовов скриптов

| Скрипт | Вызов из skill | Назначение |
|--------|----------------|-----------|
| `slugify.py` | `python3 .../slugify.py "$name"` | ASCII-slug имени файла |
| `drawio_convert.py` | `python3 .../drawio_convert.py input.drawio output.svg` | XML → SVG с embedded XML |
| `find_doc_root.sh` (новый) | `bash .../find_doc_root.sh "$target_page"` | Поиск `.doc-root.yaml` |
| MCP `mermaid_save` | через Claude MCP tool call | Сохранение mermaid DSL как SVG |

`find_doc_root.sh` — новый скрипт, создаётся Dev в `plugins/gramax/scripts/`.

## Consequences

**Положительные:**
- Атомарная запись через temp+rename исключает незавершённые файлы при ошибке (NFR-005).
- Контракт зафиксирован: Dev не принимает архитектурных решений на этапе реализации.
- Переиспользование существующих скриптов (slugify.py, drawio_convert.py) без изменений.

**Отрицательные / trade-offs:**
- `find_doc_root.sh` — новый скрипт; Dev должен создать + покрыть smoke-тестом.
- YAML-парсинг через regex — хрупко для мультистрочных значений. Mitigation: `syntax:` в `.doc-root.yaml` всегда однострочное значение (по schema).

**Открытые риски:**
- Bash 3.2 (macOS default): `mktemp` поведение может отличаться. Mitigation: `mktemp "${dir}/.tmp_XXXXXX.ext"` — валидно на bash 3.2 и новее.
- `read -r` для подтверждения overwrite не работает в non-interactive контексте (Claude Code headless). Mitigation: в headless режиме Claude передаёт ответ как параметр; skill-промпт описывает как запросить подтверждение через LLM-диалог, не shell read.

**Mitigations:**
- bash 3.2: не использовать `mapfile`, `[[ -v var ]]`, `declare -A` (ассоциативные массивы). Только POSIX-совместимые конструкции.
- Перезапись в headless: skill переспрашивает пользователя через LLM-диалог; bash-скрипт принимает флаг `--force` для неинтерактивного режима.

## Alternatives Considered

- **YAML-парсер через `python3 -c "import yaml"`** — отклонено: pyyaml не в stdlib; нарушает NFR-004.
- **Не-атомарная запись (прямой write)** — отклонено: при ошибке на шаге конвертации остаётся пустой `.svg`; NFR-005 требует атомарности.
- **Вставка ссылки всегда через LLM** — частично принято: LLM обрабатывает целевую вставку; bash — только append по умолчанию. Полный LLM-путь возможен, но медленнее и менее предсказуем для тестирования (AC-001, AC-002, AC-004, AC-005).

## Связанные артефакты

- spec: `docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md` (open question #5, #6; FR-003, FR-004, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, NFR-003, NFR-004, NFR-005; AC-001, AC-002, AC-004, AC-005, AC-006, AC-007, AC-008, AC-009, AC-010)
- затрагивает: `plugins/gramax/scripts/find_doc_root.sh` (новый), `plugins/gramax/skills/diagram-on-demand/SKILL.md`
- переиспользует: `plugins/gramax/scripts/drawio_convert.py`, `plugins/gramax/scripts/slugify.py`
