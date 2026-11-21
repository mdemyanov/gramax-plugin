#!/usr/bin/env bash
# tests/gramax/render-quality/ac-118-fast-isolation.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-118 (NFR-078)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 7
#   (изоляция --fast) и «Контракт с QA-author», строка ac-118 (варден).
# Проверка (контракт): каждое упоминание render-quality в scripts/check-gramax.sh находится
# ТОЛЬКО внутри --full-блока; в --fast-пути прибора нет (NFR-078: состав, вывод и
# длительность --fast появлением прибора не меняются).
# Цвет при создании: ЗЕЛЁНЫЙ С РОЖДЕНИЯ — упоминаний render-quality в check-gramax.sh нет
# вовсе (изоляция уже соблюдена); после регистрации шага 18 в --full-блоке варден остаётся
# зелёным; краснеет, если прибор появится вне --full-блока. Красный варден — триаж, не
# плановая краснота (дизайн: «зелёный с рождения; красный — триаж»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-118: scripts/check-gramax.sh на месте"

# Регионы: FULL — строки внутри --full-блока, OUT — строки вне его.
# Открыватель/закрыватель — в нулевой колонке; вложенные if внутри блока отбиты отступом.
REGIONS="$(awk -v probe="render-quality" '
  /^if \[ "\$MODE" = "--full" \]; then/ { infull = 1; next }
  infull && /^fi$/                      { infull = 0; next }
  $0 ~ probe { print (infull ? "FULL" : "OUT") "\t" NR "\t" $0 }
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
