#!/usr/bin/env bash
# tests/gramax/comments/ac-171-gen-comment-id-refusals.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-171 (FR-227)
# Дизайн: docs/40-architecture/2026-11-24-wave4-validators-design.md, §3.7 (единственная
# правка контракта: две границы --check, дающие сегодня traceback с rc=1, переводятся
# чтением через lib.read_page.read_page в именованный отказ в stderr с rc=2:
# «not a file: {yaml_path}» и «{yaml_path}: файл не является валидным UTF-8 (байт 0xNN на
# позиции P из S)» — вторая собирается из utf8_message), §6.7 (строка 3); ADR-0028
# Решение 7.
# Проверка (фикстура ac-171-gen-id: каталог и badbytes.comments.yaml с байтом 0xff):
#   --check <каталог> → rc=2, stderr «not a file: …», traceback нет;
#   --check <битый UTF-8> → rc=2, stderr с байтом 0xff, позицией и размером, traceback
#   нет. Позиция и размер считаются из самих байтов фикстуры (не хардкод).
# Red on 6e2db04: load_existing_ids читает read_text(encoding='utf-8') — каталог даёт
#   IsADirectoryError, битый файл — UnicodeDecodeError, оба traceback с rc=1 (замер
#   2026-11-24).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-171-gen-id"

# Эталон позиции и размера — из самих байтов фикстуры (не хардкод), как в ac-133.
read -r EXP_START EXP_SIZE < <(python3 -c "
data = open('$FIXTURE/badbytes.comments.yaml','rb').read()
try:
    data.decode('utf-8')
    print('DECODES 0 0')
except UnicodeDecodeError as e:
    print(e.start, len(data))
")

# --- граница 1: --check по каталогу ---
if OUT_DIR=$(cd "$ROOT" && uv run plugins/gramax/scripts/gen_comment_id.py --check "$FIXTURE" 2>&1 >/dev/null); then
  RC_DIR=0
else
  RC_DIR=$?
fi

if [ "$RC_DIR" -ne 2 ]; then
  echo "  FAIL: AC-171 RED — --check по каталогу даёт rc=$RC_DIR: ожидается именованный отказ с rc=2 (сегодня — traceback IsADirectoryError с rc=1, ADR-0028 Решение 7)" >&2
  printf '%s\n' "$OUT_DIR" | tail -3 >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT_DIR" | grep -qF "Traceback"; then
  echo "  FAIL: AC-171 — traceback не допускается: граница --check обязана дать именованную строку «not a file: {yaml_path}» (дизайн §3.7)" >&2
  printf '%s\n' "$OUT_DIR" | tail -5 >&2
  FAIL=$((FAIL + 1))
fi
if [ "$RC_DIR" -eq 2 ] && ! printf '%s\n' "$OUT_DIR" | grep -qF "not a file:"; then
  echo "  FAIL: AC-171 — при rc=2 stderr обязан нести «not a file: {yaml_path}» (дизайн §3.7 дословно)" >&2
  FAIL=$((FAIL + 1))
fi

# --- граница 2: --check по файлу с битым UTF-8 ---
if OUT_BYTES=$(cd "$ROOT" && uv run plugins/gramax/scripts/gen_comment_id.py --check "$FIXTURE/badbytes.comments.yaml" 2>&1 >/dev/null); then
  RC_BYTES=0
else
  RC_BYTES=$?
fi

if [ "$RC_BYTES" -ne 2 ]; then
  echo "  FAIL: AC-171 RED — --check по файлу с битым UTF-8 даёт rc=$RC_BYTES: ожидается именованный отказ с rc=2 (сегодня — traceback UnicodeDecodeError с rc=1, ADR-0028 Решение 7)" >&2
  printf '%s\n' "$OUT_BYTES" | tail -3 >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT_BYTES" | grep -qF "Traceback"; then
  echo "  FAIL: AC-171 — traceback UnicodeDecodeError не допускается: чтение обязано идти через read_page с диагностикой байта (дизайн §3.7)" >&2
  printf '%s\n' "$OUT_BYTES" | tail -5 >&2
  FAIL=$((FAIL + 1))
fi
if [ "$RC_BYTES" -eq 2 ] && ! printf '%s\n' "$OUT_BYTES" | grep -qF "файл не является валидным UTF-8 (байт 0xff на позиции $EXP_START из $EXP_SIZE)"; then
  echo "  FAIL: AC-171 — при rc=2 stderr обязан нести «{path}: файл не является валидным UTF-8 (байт 0xff на позиции $EXP_START из $EXP_SIZE)» (дизайн §3.7, utf8_message)" >&2
  printf '%s\n' "$OUT_BYTES" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-171: AC-171 — $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-171: AC-171 — границы --check дают именованный отказ rc=2 без traceback (каталог; битый UTF-8 с байтом/позицией/размером)"
