#!/usr/bin/env bash
# validate_diagram_type.sh — проверяет поддержку mermaid-типа в Gramax
#
# Использование:
#   bash validate_diagram_type.sh <type>
#   bash validate_diagram_type.sh --dsl <mermaid-dsl-text>
#
# Exit codes:
#   0 — тип поддерживается (или предупреждение о неподдерживаемом типе — exit 0 по spec)
#   2 — тип не поддерживается (при вызове с --dsl и strict mode)
#
# Поддерживаемые типы Gramax (из mermaid-blocks.md):
#   flowchart, sequenceDiagram, gantt, classDiagram,
#   stateDiagram-v2, erDiagram, pie, mindmap
#
# Неподдерживаемые типы (FR-005):
#   gitGraph, journey, requirementDiagram, C4Context

set -euo pipefail

SUPPORTED_TYPES="flowchart sequenceDiagram gantt classDiagram stateDiagram-v2 erDiagram pie mindmap"
UNSUPPORTED_TYPES="gitGraph journey requirementDiagram C4Context"

usage() {
  echo "Usage: validate_diagram_type.sh <type>" >&2
  echo "       validate_diagram_type.sh --dsl <mermaid-dsl-text>" >&2
  exit 1
}

# Извлекает первое слово (тип) из mermaid DSL
extract_type_from_dsl() {
  local dsl="$1"
  # Первое непустое слово первой непустой строки
  echo "$dsl" | grep -m1 -oE '[a-zA-Z][a-zA-Z0-9-]*' | head -1
}

is_supported() {
  local type="$1"
  for t in $SUPPORTED_TYPES; do
    if [ "$t" = "$type" ]; then
      return 0
    fi
  done
  return 1
}

is_explicitly_unsupported() {
  local type="$1"
  for t in $UNSUPPORTED_TYPES; do
    if [ "$t" = "$type" ]; then
      return 0
    fi
  done
  return 1
}

if [ $# -lt 1 ]; then
  usage
fi

DIAGRAM_TYPE=""

if [ "$1" = "--dsl" ]; then
  if [ $# -lt 2 ]; then
    usage
  fi
  DIAGRAM_TYPE="$(extract_type_from_dsl "$2")"
else
  DIAGRAM_TYPE="$1"
fi

if [ -z "$DIAGRAM_TYPE" ]; then
  echo "[WARN] Тип диаграммы не определён. Укажи явный тип или DSL-содержимое." >&2
  exit 1
fi

if is_supported "$DIAGRAM_TYPE"; then
  # Поддерживаемый тип — тихо завершаемся
  exit 0
fi

# Неподдерживаемый тип — выводим [WARN] в stdout (spec: exit code 0, не ошибка)
echo "[WARN] Тип ${DIAGRAM_TYPE} не поддерживается Gramax. Рекомендуется: flowchart или drawio."
exit 0
