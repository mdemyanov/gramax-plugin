#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-175-submodule-status-removed.sh
# Требование: docs/30-requirements/2026-11-24-wave4-contracts-gates-requirement.md — AC-175 (FR-229)
# Решение: ADR-0029 (вне индекса на момент письма), Решение 5, строка 2 — шаг `submodule
#   status` (scripts/check-gramax.sh:182-189; заголовок :11 и :103) удаляется: исход «шаг
#   снят с записью в ADR» из формулировки AC-175.
# Основание решения (замер ADR-0029): `git submodule status` → 0 строк, `.gitmodules` нет;
#   ни один стаб шаг не держит — шагу нет предмета.
# Проверка (контракт):
#   (a) литерал «submodule» не встречается в scripts/check-gramax.sh нигде — ни в исполняемых
#       строках, ни в заголовке-самописце (комментарий тоже дрейфует состав);
#   (b) варден основания: `git submodule status` даёт 0 строк и `.gitmodules` не существует —
#       появление сабмодуля лишает решение предмета и красит стаб (триггер возврата: шаг
#       возвращается осознанным решением, а не молчаливой правкой).
# Цвет на текущем дереве: КРАСНЫЙ — шаг ещё в гейте (:11, :103, :183-188); мутация к
#   зелёному — удаление шага Dev (Решение 5, строка 2). Варден (b) зелёный от рождения.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-175: scripts/check-gramax.sh на месте"

# --- (a): шаг снят целиком — ни слова о submodule в гейте ---
assert_no_grep_regex "$CHECK_GRAMAX" 'submodule' \
  "AC-175: шаг submodule status снят (ADR-0029 Решение 5, строка 2) — литерала submodule в check-gramax.sh нет ни в теле, ни в заголовке-самописце"

# --- (b): варден основания решения — предмета по-прежнему нет ---
SUB_COUNT="$(git -C "$ROOT" submodule status 2>/dev/null | grep -c . || true)"
if [ "${SUB_COUNT:-0}" -ne 0 ]; then
  echo "  FAIL: AC-175 — git submodule status даёт ${SUB_COUNT} строк(и): основание снятия" >&2
  echo "  шага («0 строк, .gitmodules нет» — ADR-0029 Решение 5, строка 2) перестало держаться;" >&2
  echo "  шаг рассинхрона возвращается осознанным решением (AC-175, ветка «шаг может упасть»)" >&2
  FAIL=$((FAIL + 1))
fi
if [ -f "$ROOT/.gitmodules" ]; then
  echo "  FAIL: AC-175 — .gitmodules появился: решение о снятии шага подлежит пересмотру" >&2
  echo "  (основание ADR-0029 Решение 5, строка 2 больше не выполняется)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-175: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-175: шаг submodule status снят (submodule в check-gramax.sh не упоминается); основание цел — 0 сабмодулей, .gitmodules нет"
