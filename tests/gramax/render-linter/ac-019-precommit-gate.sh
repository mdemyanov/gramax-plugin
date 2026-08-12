#!/usr/bin/env bash
# tests/gramax/render-linter/ac-019-precommit-gate.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-019 (FR-119)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 4
# Проверка: прогон линтера на content/ подключён к повторяемой проверке (check.sh),
#           а не разовый ручной — команда присутствует в шаге, исполняемом гейтом.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

assert_grep "$ROOT/scripts/check.sh" "validate_render.py" \
  "AC-019: scripts/check.sh обязан вызывать validate_render.py (pre-commit-перехват киллеров рендера)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-019: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-019: validate_render.py подключён к check.sh (гейт исполняет шаг)"
