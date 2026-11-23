#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-133-broken-utf8-traversal.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-133 (FR-212)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.4 (E036
# дословно), §2.5 (чтение через общий примитив; ровно одна находка на файл; альтернатива
# UTF-8 в паттерне группы content), ADR-0026 Решение 6.
# Проверка: каталог с broken.md (оборванный байт 0xd0) и bait-unpaired-note.md
#   (здоровый файл с настоящим дефектом unpaired <note>) →
#   (a) rc=1; (b) traceback нет; (c) ровно одна E036-строка; (d) E036 называет путь битого
#   файла, байт 0xd0 и позицию/размер, вычисленные по фикстуре; (e) находка bait-файла
#   присутствует — обход доведён до конца.
# Red on 7553da1: read_text без обработки UnicodeDecodeError → traceback, обрыв обхода
#   (замер 2026-11-23: UnicodeDecodeError: invalid continuation byte).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-133-utf8"

# Эталон позиции и размера — из самих байтов фикстуры (не хардкод).
read -r EXP_START EXP_SIZE EXP_HEX < <(python3 -c "
data = open('$FIXTURE/broken.md','rb').read()
try:
    data.decode('utf-8')
    print('DECODES 0 0 0x00')
except UnicodeDecodeError as e:
    print(e.start, len(data), f'0x{data[e.start]:02x}')
")

OUT_FILE="$SCRIPT_DIR/.ac-133-out.txt"
if (cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" > "$OUT_FILE" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "1" "AC-133: битый UTF-8 — rc=1 (код выхода не меняется, ADR-0026 Consequences)"

if grep -q "Traceback" "$OUT_FILE"; then
  echo "  FAIL: AC-133 — traceback UnicodeDecodeError вместо именованной находки (FR-212)" >&2
  FAIL=$((FAIL + 1))
fi

E036_COUNT=$(grep -c "E036" "$OUT_FILE")
assert_eq "$E036_COUNT" "1" "AC-133: ровно одна E036-находка на файл, сколько бы проверок его ни читали (BR-004, дизайн §6)"

if ! grep -F "broken.md" "$OUT_FILE" | grep -q "E036"; then
  echo "  FAIL: AC-133 — E036 обязана называть путь битого файла" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep "E036" "$OUT_FILE" | grep -qF "$EXP_HEX"; then
  echo "  FAIL: AC-133 — E036 обязана называть байт $EXP_HEX (дизайн §2.4)" >&2
  FAIL=$((FAIL + 1))
fi
if ! grep "E036" "$OUT_FILE" | grep -qF "на позиции $EXP_START из $EXP_SIZE"; then
  echo "  FAIL: AC-133 — E036 обязана называть позицию байта (начало $EXP_START) и размер файла ($EXP_SIZE байт), форма апстрим-линтера" >&2
  FAIL=$((FAIL + 1))
fi

if ! grep -qF "unpaired <note>" "$OUT_FILE"; then
  echo "  FAIL: AC-133 — находка здорового bait-файла (unpaired <note>) обязана появиться: обход доведён до конца, не оборван битым файлом" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$OUT_FILE"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-133: AC-133 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-133: AC-133 — E036 ($EXP_HEX на позиции $EXP_START из $EXP_SIZE), без traceback, обход полный, rc=1"
