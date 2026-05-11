#!/usr/bin/env bash
# find_doc_root.sh — обходит дерево каталогов вверх в поисках .doc-root.yaml
#
# Использование:
#   bash find_doc_root.sh <path-to-file-or-dir>
#
# Выходные данные (stdout):
#   Абсолютный путь к найденному .doc-root.yaml файлу
#
# Exit codes:
#   0 — файл найден (путь напечатан в stdout)
#   1 — файл не найден во всём дереве вверх до корня FS
#
# Поддерживает кириллицу в путях через LC_ALL=C.UTF-8

set -euo pipefail
export LC_ALL=C.UTF-8

if [ $# -lt 1 ]; then
  echo "Usage: find_doc_root.sh <path-to-file-or-dir>" >&2
  exit 1
fi

INPUT="$1"

# Определяем начальную директорию: если передан файл — берём его директорию
if [ -f "$INPUT" ]; then
  START_DIR="$(cd "$(dirname "$INPUT")" && pwd)"
elif [ -d "$INPUT" ]; then
  START_DIR="$(cd "$INPUT" && pwd)"
else
  # Путь не существует — берём директорию как строку (для тестовых сценариев)
  START_DIR="$(cd "$(dirname "$INPUT")" && pwd 2>/dev/null)" || START_DIR="$(dirname "$INPUT")"
fi

dir="$START_DIR"

while true; do
  if [ -f "$dir/.doc-root.yaml" ]; then
    echo "$dir/.doc-root.yaml"
    exit 0
  fi
  # Достигли корня файловой системы — прекращаем
  parent="$(dirname "$dir")"
  if [ "$parent" = "$dir" ]; then
    break
  fi
  dir="$parent"
done

exit 1
