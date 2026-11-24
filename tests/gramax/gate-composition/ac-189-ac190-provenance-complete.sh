#!/usr/bin/env bash
# tests/gramax/gate-composition/ac-189-ac190-provenance-complete.sh
# Требование: docs/30-requirements/2026-11-24-wave4-docs-decisions-requirement.md (вне индекса
#   на момент письма) — AC-189, AC-190 (FR-242, карточка gramax-o0q.14).
# Прибор: scripts/check-content-actuality.py (ADR-076: опоры резолвятся по git ls-files;
#   исходы Д5: 0 — «актуален»/«объявленный отказ», 1 — «неопределим», 3 — «устарел»).
# Проверка (контракт): гейт актуальности на docs/ завершается кодом 0, сводка несёт
#   «неопределим: 0» (AC-189 — каждая статья несёт маркер «Опоры» с tracked-путями либо
#   строку «**Опоры:** нет — <причина>») и «устарел: 0» (AC-190 — каждый названный путь
#   резолвится в git ls-files как файл; отказ без причины классифицируется прибором как
#   «неопределим», поэтому ноль там покрывает и форму отказов — причины названы).
# Цвет на момент письма (2026-11-24): ЗЕЛЁНЫЙ ГАРД — сводка «Область: 125 (вне выборки: 13) |
#   актуален: 122 | объявленный отказ: 3 | неопределим: 0 | устарел: 0», rc=0 (замер роли).
# Мутации к красному (показаны в at-design 2026-11-24-wave4-docs-at-design.md, /tmp-копия
#   docs с git init): статья без маркера → «неопределим: 1», rc=1; маркер с путём вне
#   git ls-files → «устарел: 1», rc=3. Числа «Область/актуален/отказ» не пришиты — корпус
#   растёт, пин держит только нули и код возврата.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
GATE="$ROOT/scripts/check-content-actuality.py"
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT

assert_file_exists "$GATE" "AC-189: прибор check-content-actuality.py на месте"

PYTHONDONTWRITEBYTECODE=1 python3 -B "$GATE" --content-dir "$ROOT/docs" > "$OUT" 2>&1
RC=$?
SUMMARY="$(grep -F 'Область:' "$OUT" || true)"

assert_exit_zero "$RC" \
  "AC-189/AC-190: rc гейта актуальности = 0 (1 — есть «неопределим», 3 — есть «устарел», 2 — крушение вызова)"

if printf '%s\n' "$SUMMARY" | grep -qF 'неопределим: 0'; then
  :
else
  echo "  FAIL: AC-189 — в сводке гейта «неопределим» не 0: ${SUMMARY:-<сводки нет>}" >&2
  echo "  (каждая статья корпуса несёт маркер «Опоры» с конкретными tracked-путями либо" >&2
  echo "  строку «**Опоры:** нет — <причина>»; отказ без причины прибор считает «неопределим»)" >&2
  FAIL=$((FAIL + 1))
fi

if printf '%s\n' "$SUMMARY" | grep -qF 'устарел: 0'; then
  :
else
  echo "  FAIL: AC-190 — в сводке гейта «устарел» не 0: ${SUMMARY:-<сводки нет>}" >&2
  echo "  (каждый путь в строках «Опоры» резолвится в git ls-files и является файлом;" >&2
  echo "  неразрешимый путь — исход «устарел», код 3, ADR-076 Д5)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-189/190: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-189/190: провенанс полный — «неопределим: 0», «устарел: 0», rc=0; сводка: ${SUMMARY}"
