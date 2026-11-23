#!/usr/bin/env bash
# tests/gramax/render-quality/ac-118-fast-isolation.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-118 (NFR-078)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 7
#   (изоляция --fast) и «Контракт с QA-author», строка ac-118 (варден).
# Проверка (контракт, перевод по ADR-0027 «Целевой состав --full», NFR-084 — сила
# сохраняется, не удаляется и не ослабляется): каждое ИСПОЛНЯЕМОЕ упоминание
# render-quality в scripts/check-gramax.sh находится ТОЛЬКО внутри --full-блока; в
# --fast-пути прибора нет (NFR-078: состав, вывод и длительность --fast появлением
# прибора не меняются). Комментарий заголовка с render-quality (состав сюит по
# ADR-0027) — не «вне --full»: варден судит исполняемые строки, комментарии исключены.
# Цвет: ЗЕЛЁНЫЙ С РОЖДЕНИЯ и после перевода (изоляция соблюдена); краснеет, если
# исполняемая строка с прибором появится вне --full-блока. Красный варден — триаж,
# не плановая краснота (дизайн: «зелёный с рождения; красный — триаж»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-118: scripts/check-gramax.sh на месте"

# Регионы: FULL — строки внутри --full-блока, OUT — строки вне его.
# Открыватель/закрыватель — в нулевой колонке; вложенные if внутри блока отбиты отступом.
# Перевод ADR-0027: комментарий заголовка с render-quality не «вне --full» — строки,
# чей первый непробельный символ «#», не исполняются и не судятся.
REGIONS="$(awk -v probe="render-quality" '
  /^if \[ "\$MODE" = "--full" \]; then/ { infull = 1; next }
  infull && /^fi$/                      { infull = 0; next }
  {
    l = $0; sub(/^[ \t]+/, "", l)
    if (l ~ /^#/) next
    if ($0 ~ probe) print (infull ? "FULL" : "OUT") "\t" NR "\t" $0
  }
' "$CHECK_GRAMAX")"

OUTSIDE="$(printf '%s\n' "$REGIONS" | grep -c '^OUT' || true)"
if [ "$OUTSIDE" -gt 0 ]; then
  echo "  FAIL: AC-118/NFR-078 — упоминания render-quality ВНЕ --full-блока check-gramax.sh:" >&2
  printf '%s\n' "$REGIONS" | grep '^OUT' | head -10 >&2
  echo "  прибор не имеет права исполняться --fast-путём (изоляция --fast, Решение 7)" >&2
  FAIL=$((FAIL + 1))
fi

TOTAL="$(printf '%s\n' "$REGIONS" | grep -c '^FULL' || true)"
pass_msg "ac-118: упоминаний render-quality вне --full-блока: $OUTSIDE; внутри --full-блока: $TOTAL"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-118: $FAIL assertion(s) failed"; exit 1; fi
exit 0
