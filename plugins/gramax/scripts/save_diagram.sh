#!/usr/bin/env bash
# save_diagram.sh — атомарная запись drawio XML + SVG-конвертация
#
# Использование:
#   bash save_diagram.sh --xml <mxfile-content> --output-drawio <path.drawio> --output-svg <path.svg> [--force]
#
# Переменные окружения:
#   DIAGRAM_DRAWIO_MCP=disabled  — пропустить MCP-конвертацию (использовать только drawio_convert.py)
#                                   При недоступном MCP: .drawio сохраняется, .svg не создаётся, exit 1
#
# Exit codes:
#   0 — успешно сохранено (и .drawio, и .svg)
#   0 — файл уже существует без --force (с [WARN] в stdout)
#   1 — ошибка конвертации (drawio_convert.py вернул ошибку, .drawio сохранён)
#   1 — невалидный XML
#   1 — MCP недоступен (.drawio сохранён, .svg не создан)

set -uo pipefail
export LC_ALL=C.UTF-8

# Определяем путь к директории скриптов плагина
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

XML_CONTENT=""
OUTPUT_DRAWIO=""
OUTPUT_SVG=""
FORCE=0

# Парсинг аргументов
while [ $# -gt 0 ]; do
  case "$1" in
    --xml)
      XML_CONTENT="$2"
      shift 2
      ;;
    --output-drawio)
      OUTPUT_DRAWIO="$2"
      shift 2
      ;;
    --output-svg)
      OUTPUT_SVG="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# Валидация обязательных параметров
if [ -z "$XML_CONTENT" ]; then
  echo "[ERROR] --xml is required" >&2
  exit 1
fi

if [ -z "$OUTPUT_DRAWIO" ]; then
  echo "[ERROR] --output-drawio is required" >&2
  exit 1
fi

if [ -z "$OUTPUT_SVG" ]; then
  echo "[ERROR] --output-svg is required" >&2
  exit 1
fi

# Базовое имя для сообщений
DRAWIO_BASENAME="$(basename "$OUTPUT_DRAWIO")"

# Проверка существующего файла (AC-010, FR-007)
if [ "$FORCE" -eq 0 ] && { [ -f "$OUTPUT_DRAWIO" ] || [ -f "$OUTPUT_SVG" ]; }; then
  echo "[WARN] Файл ${OUTPUT_DRAWIO} уже существует. Перезаписать? Используй --force для перезаписи без подтверждения."
  exit 0
fi

# Валидация XML через python3 (AC-012)
python3 -c "
import xml.etree.ElementTree as ET, sys
try:
    ET.fromstring(sys.argv[1])
except ET.ParseError as e:
    print(f'[ERROR] Невалидный XML: {e}', file=sys.stderr)
    sys.exit(1)
" "$XML_CONTENT" || exit 1

# Директория для выходных файлов
TARGET_DIR="$(dirname "$OUTPUT_DRAWIO")"
mkdir -p "$TARGET_DIR"

# Атомарная запись .drawio через temp+rename (ADR-0005 раздел 4, NFR-005)
TMP_DRAWIO=$(mktemp "${TARGET_DIR}/.tmp_XXXXXX.drawio")
printf '%s' "$XML_CONTENT" > "$TMP_DRAWIO"
mv "$TMP_DRAWIO" "$OUTPUT_DRAWIO"

# Проверка доступности MCP drawio (через переменную окружения)
MCP_STATUS="${DIAGRAM_DRAWIO_MCP:-enabled}"

if [ "$MCP_STATUS" = "disabled" ]; then
  # MCP недоступен — сообщаем в stderr, .drawio уже сохранён
  echo "[ERROR] MCP drawio-бэкенд недоступен. ${DRAWIO_BASENAME} сохранён." >&2
  echo "[ERROR] Для ручной конвертации: python3 ${SCRIPTS_DIR}/drawio_convert.py ${OUTPUT_DRAWIO} ${OUTPUT_SVG}" >&2
  exit 1
fi

# Конвертация в SVG через drawio_convert.py (атомарно)
TMP_SVG=$(mktemp "${TARGET_DIR}/.tmp_XXXXXX.svg")
if python3 "${SCRIPTS_DIR}/drawio_convert.py" "$OUTPUT_DRAWIO" "$TMP_SVG"; then
  mv "$TMP_SVG" "$OUTPUT_SVG"
else
  rm -f "$TMP_SVG"
  echo "[ERROR] drawio_convert.py завершился с ошибкой. ${DRAWIO_BASENAME} сохранён." >&2
  echo "[ERROR] Для ручной конвертации: python3 ${SCRIPTS_DIR}/drawio_convert.py ${OUTPUT_DRAWIO} ${OUTPUT_SVG}" >&2
  exit 1
fi

echo "Created: ${OUTPUT_DRAWIO}"
echo "Created: ${OUTPUT_SVG}"
exit 0
