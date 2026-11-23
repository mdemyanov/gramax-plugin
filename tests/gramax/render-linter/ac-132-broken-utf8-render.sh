#!/usr/bin/env bash
# tests/gramax/render-linter/ac-132-broken-utf8-render.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-132 (FR-212)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §2.4
# («ERROR L0: Файл не является валидным UTF-8 (байт 0x{hex} на позиции {start} из {size})» —
# форма апстрим-линтера дословно), §2.5 (check() → одна ошибка (0, сообщение)), ADR-0026
# Решение 6; beads gramax-4jf.5.
# Проверка (каталог из трёх файлов: битый, здоровый с настоящим дефектом, чистый):
#   (a) rc=1; (b) traceback нет; (c) «FAIL <путь битого>» и дословная строка
#       «ERROR L0: …» с байтом 0xd0 и позицией/размером, вычисленными по фикстуре;
#   (d) ERROR здорового bait-файла присутствует — остальные файлы проверены;
#   (e) чистый файл — OK.
# Red on 7553da1: path.read_text в check() (validate_render.py:75) без обработки
#   UnicodeDecodeError → traceback, обход обрывается (замер 2026-11-23).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-132-utf8-dir"

read -r EXP_START EXP_SIZE EXP_HEX < <(python3 -c "
data = open('$FIXTURE/broken.md','rb').read()
try:
    data.decode('utf-8')
    print('DECODES 0 0 0x00')
except UnicodeDecodeError as e:
    print(e.start, len(data), f'0x{data[e.start]:02x}')
")

OUT_FILE="$SCRIPT_DIR/.ac-132-out.txt"
if (cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" > "$OUT_FILE" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "1" "AC-132: битый UTF-8 — rc=1 (rc-контракт 0/1/2 не меняется, ADR-0026 Consequences)"

if grep -q "Traceback" "$OUT_FILE"; then
  echo "  FAIL: AC-132 — traceback UnicodeDecodeError вместо именованной находки (FR-212; замер 2026-11-23: UnicodeDecodeError)" >&2
  FAIL=$((FAIL + 1))
fi

if ! grep -qF "FAIL $FIXTURE/broken.md" "$OUT_FILE"; then
  echo "  FAIL: AC-132 — обязан быть заголовок «FAIL <путь битого файла>»" >&2
  FAIL=$((FAIL + 1))
fi

if ! grep -qF "ERROR L0: Файл не является валидным UTF-8 (байт $EXP_HEX на позиции $EXP_START из $EXP_SIZE)" "$OUT_FILE"; then
  echo "  FAIL: AC-132 — строка «ERROR L0: Файл не является валидным UTF-8 (байт $EXP_HEX на позиции $EXP_START из $EXP_SIZE)» обязана быть дословной (дизайн §2.4; L0 — не строка разметки)" >&2
  FAIL=$((FAIL + 1))
fi

if ! grep -qF "Инлайновый <note>" "$OUT_FILE"; then
  echo "  FAIL: AC-132 — ERROR здорового bait-файла (инлайновый <note>) обязан присутствовать: остальные файлы каталога проверены" >&2
  FAIL=$((FAIL + 1))
fi

if ! grep -qF "OK   $FIXTURE/clean.md" "$OUT_FILE"; then
  echo "  FAIL: AC-132 — чистый файл обязан получить OK (обход доведён до конца)" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$OUT_FILE"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-132: AC-132 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-132: AC-132 — FAIL + ERROR L0 дословно ($EXP_HEX, $EXP_START из $EXP_SIZE), обход полный, rc=1"
