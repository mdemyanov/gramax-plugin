#!/usr/bin/env bash
# tests/gramax/render-quality/ac-113-full-only.sh
# Требование: docs/30-requirements/2026-11-21-playwright-render-quality-requirement.md — AC-113 (FR-194)
# Дизайн: docs/40-architecture/2026-11-21-playwright-render-quality-design.md, Решение 7
#   (шаг 18 в --full-блоке scripts/check-gramax.sh, регистрация только после позеленения)
#   и «Контракт с QA-author», строка ac-113.
# Проверка (контракт): в scripts/check-gramax.sh сюита render-quality вызывается внутри
# --full-блока (bash tests/gramax/render-quality/run.sh); шага в --fast-пути нет.
# Цвет при создании: КРАСНЫЙ ПО ИМЕНИ — шага 18 в check-gramax.sh ещё нет; эта краснота и
# есть TDD-цель Dev (дизайн: «красный до регистрации шага 18 …, зелёный после»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
CHECK_GRAMAX="$ROOT/scripts/check-gramax.sh"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
assert_file_exists "$CHECK_GRAMAX" "AC-113: scripts/check-gramax.sh на месте"

# Регион --full-блока: открывается строкой `if [ "$MODE" = "--full" ]; then` в нулевой
# колонке, закрывается `fi` в нулевой колонке (вложенные if внутри блока отбиты отступом).
FULL_LINES="$(
  awk '
    /^if \[ "\$MODE" = "--full" \]; then/ { infull = 1; next }
    infull && /^fi$/                      { infull = 0; next }
    { if (infull) print NR "\t" $0 }
  ' "$CHECK_GRAMAX"
)"

if printf '%s\n' "$FULL_LINES" | grep -q 'tests/gramax/render-quality'; then
  :
else
  echo "  FAIL: AC-113 — в --full-блоке scripts/check-gramax.sh нет вызова" >&2
  echo "  bash tests/gramax/render-quality/run.sh; регистрация шага 18 — TDD-цель Dev" >&2
  echo "  (дизайн, Решение 7: регистрация тем же коммитом позеленения, FR-194)" >&2
  FAIL=$((FAIL + 1))
fi

# Позитив формы: вызов — дом-паттерн шага гейта (run.sh, а не отдельные ac-*.sh)
if printf '%s\n' "$FULL_LINES" | grep -qF 'bash tests/gramax/render-quality/run.sh'; then
  :
else
  echo "  FAIL: AC-113 — вызов сюиты обязан идти через run.sh (агрегатор, дом-паттерн шага)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-113: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-113: render-quality зарегистрирован шагом --full через run.sh, в --fast-пути шага нет"
