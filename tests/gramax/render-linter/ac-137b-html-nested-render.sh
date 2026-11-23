#!/usr/bin/env bash
# tests/gramax/render-linter/ac-137b-html-nested-render.sh
# Требование: docs/30-requirements/2026-11-23-wave3-validators-contracts-gates-requirement.md — AC-137 (FR-216)
# Дизайн: docs/40-architecture/2026-11-23-wave3-validator-contracts-design.md, §6 AC-137
# (маска применяется ПОСЛЕ _mask_code; читают маску построчные проверки и баланс);
# контракт вложенности — правка регрессии замера 2026-11-23: _mask_html_blocks убирает
# СОДЕРЖИМОЕ между html-тегами, но не сами теги <html …>/</html> — при вложенных блоках
# хвост обёртки (между </html> внутреннего блока и закрывающим </html> обёртки) тоже
# замаскирован (регрессия: нерасширяющееся сопоставление «до ближайшего </html>» оставляло
# этот хвост видимым — приманка в нём давала ложный ERROR баланса).
# Проверка:
#   (a) приманки во вложенных блоках (инлайновый <note> внутри внутреннего блока +
#       незакрытый <td> в хвосте обёртки) → ERROR нет, rc=0;
#   (b) нога-варден: незакрытый <td> вне всяких блоков — по-прежнему ERROR, rc=1
#       (маска не глушит файл целиком).
# Red on d6ccab7: приманка в хвосте обёртки видна — «Несбалансированный
#   <td>», rc=1 вместо 0.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
BAIT="$SCRIPT_DIR/fixtures/ac-137b-html-nested.md"
OUTSIDE="$SCRIPT_DIR/fixtures/ac-137b-html-outside-defect.md"

# --- (a): приманки во вложенных блоках молчат ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$BAIT" 2>&1); then
  RC=0
else
  RC=$?
fi

if printf '%s\n' "$OUT" | grep -qF "Инлайновый <note>"; then
  echo "  FAIL: AC-137b — инлайновый <note> внутри внутреннего html-блока не должен проверяться как разметка страницы (FR-216)" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT" | grep -qF "Несбалансированный <td>"; then
  echo "  FAIL: AC-137b — незакрытый <td> в хвосте обёртки (между </html> внутреннего блока и </html> обёртки) внутри html-блока: обязан быть замаскирован при вложенности" >&2
  FAIL=$((FAIL + 1))
fi
assert_exit_zero "$RC" "AC-137b: файл-приманка (дефекты только внутри вложенных html-блоков) — rc=0"

# --- (b): варден — дефект вне блоков ловится как прежде ---
if OUT_OUTSIDE=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$OUTSIDE" 2>&1); then
  RC_OUTSIDE=0
else
  RC_OUTSIDE=$?
fi
assert_eq "$RC_OUTSIDE" "1" "AC-137b варден: незакрытый <td> вне html-блоков — rc=1 (маска не глушит файл целиком)"
if ! printf '%s\n' "$OUT_OUTSIDE" | grep -qF "Несбалансированный <td>"; then
  echo "  FAIL: AC-137b варден — <td> вне блоков обязан давать баланс-ERROR: маска не должна скрывать разметку вне html-блоков" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод validate_render (приманка) ---" >&2
  printf '%s\n' "$OUT" >&2
  fail_msg "ac-137b: AC-137b (рендер) — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-137b: вложенные html-блоки — содержимое (включая хвост обёртки) молчит, дефект вне блоков ловится"
