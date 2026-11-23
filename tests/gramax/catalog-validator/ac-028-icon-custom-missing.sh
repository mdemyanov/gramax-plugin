#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-028-icon-custom-missing.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-155 (FR-153)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (новая проверка check_icons,
# код находки W035, сообщение называет код и ожидаемый путь .icons/<code>.svg; ADR-0024 Решения 1/2/5)
# Проверка: <icon code="my-custom-icon"/> без .icons/my-custom-icon.svg → вывод называет код иконки
# Red on 99201c0 (2026-11-18): проверки иконок нет ни в каком виде (grep '.icons' plugins/gramax —
# 0 совпадений); W034 на <icon> эхолит только имя тега, без кода — упоминаний 'my-custom-icon' ноль.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/icons-missing"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if ! echo "$OUT" | grep -qF 'my-custom-icon'; then
  echo "  FAIL: AC-155 — вывод должен называть кастомный код 'my-custom-icon' и ожидаемый путь .icons/my-custom-icon.svg (W035, FR-153)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-028: AC-155 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-028: AC-155 — отсутствующая .icons-иконка обнаруживается (W035)"
