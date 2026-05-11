#!/usr/bin/env bash
# insert_diagram_ref.sh — вставляет ссылку на диаграмму в md-файл
#
# Использование:
#   bash insert_diagram_ref.sh --target <md-file> --syntax <XML|Markdown> --svg-name <name.svg> [--alt <text>]
#   bash insert_diagram_ref.sh --target <md-file> --syntax <XML|Markdown> --mermaid-dsl <dsl-text>
#
# Режимы:
#   --svg-name    : вставляет ссылку на SVG-файл (drawio и mermaid в виде файла)
#   --mermaid-dsl : вставляет fenced mermaid блок или <mermaid> тег (инлайн DSL)
#
# Exit codes:
#   0 — успешно вставлено
#   1 — md-файл не найден
#   2 — ошибка вставки

set -euo pipefail
export LC_ALL=C.UTF-8

TARGET_MD=""
SYNTAX=""
SVG_NAME=""
MERMAID_DSL=""
ALT_TEXT=""

# Парсинг аргументов
while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      TARGET_MD="$2"
      shift 2
      ;;
    --syntax)
      SYNTAX="$2"
      shift 2
      ;;
    --svg-name)
      SVG_NAME="$2"
      shift 2
      ;;
    --mermaid-dsl)
      MERMAID_DSL="$2"
      shift 2
      ;;
    --alt)
      ALT_TEXT="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

# Валидация обязательных параметров
if [ -z "$TARGET_MD" ]; then
  echo "[ERROR] --target is required" >&2
  exit 2
fi

if [ ! -f "$TARGET_MD" ]; then
  echo "[ERROR] md-файл не найден: $TARGET_MD" >&2
  exit 1
fi

if [ -z "$SYNTAX" ]; then
  echo "[ERROR] --syntax is required (XML|Markdown)" >&2
  exit 2
fi

if [ -z "$SVG_NAME" ] && [ -z "$MERMAID_DSL" ]; then
  echo "[ERROR] Укажи --svg-name или --mermaid-dsl" >&2
  exit 2
fi

# Формируем фрагмент для вставки
if [ -n "$MERMAID_DSL" ]; then
  # Вставка mermaid DSL инлайн
  if [ "$SYNTAX" = "XML" ]; then
    # XML-syntax: <mermaid>...</mermaid>
    FRAGMENT="
<mermaid>
${MERMAID_DSL}
</mermaid>"
  else
    # Markdown-syntax: fenced ```mermaid...```
    FRAGMENT="
\`\`\`mermaid
${MERMAID_DSL}
\`\`\`"
  fi
elif [ -n "$SVG_NAME" ]; then
  # Вставка ссылки на SVG-файл
  if [ "$SYNTAX" = "XML" ]; then
    if [ -n "$ALT_TEXT" ]; then
      FRAGMENT="
<Image src=\"${SVG_NAME}\" alt=\"${ALT_TEXT}\" />"
    else
      FRAGMENT="
<Image src=\"${SVG_NAME}\" />"
    fi
  else
    ALT="${ALT_TEXT:-diagram}"
    FRAGMENT="
![${ALT}](${SVG_NAME})"
  fi
fi

# Append в конец файла (дефолт по ADR-0005 раздел 6)
printf '%s\n' "$FRAGMENT" >> "$TARGET_MD"
exit 0
