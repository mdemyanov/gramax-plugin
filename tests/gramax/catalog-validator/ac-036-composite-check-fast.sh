#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-036-composite-check-fast.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-163 (композитный)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (Бриф для Dev, шаг 5:
# прогон suite + check.sh --fast после реализации)
# Проверка: bash scripts/check.sh --fast && echo PASS — композитный гейт репозитория зелёный
# Warden — AC-163 сформулирован как послепубликационный гейт: обязан быть зелёным ПОСЛЕ
# публикации изменения. На момент авторской предпроверки (run-quiet, 2026-11-18, 99201c0) —
# exit 0; к завершению авторской задачи гейт КРАСНЫЙ по внешней причине: параллельный поток
# export-skill положил docs/60-implementation/test-reports/2026-11-18-export-skill-qa-report.md
# без регистрации в _index.md (docs/-гейт, вне зоны QA-author validators-parity). Красный
# результат — всегда триаж: запусти `bash scripts/check.sh --fast` вручную и раздели
# (а) внешние docs/-причины параллельных потоков, (б) незавершённую реализацию Dev,
# (в) регрессию от этого изменения. Suite catalog-validator в check.sh не подключён — рекурсии нет.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

if ! (cd "$ROOT" && bash scripts/check.sh --fast) >/dev/null 2>&1; then
  echo "  FAIL: AC-163 — композитный гейт 'bash scripts/check.sh --fast' красный; запусти вручную для деталей (триаж: параллельные потоки / незавершённая реализация)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-036: AC-163 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-036: AC-163 — композитный гейт check.sh --fast зелёный (PASS)"
