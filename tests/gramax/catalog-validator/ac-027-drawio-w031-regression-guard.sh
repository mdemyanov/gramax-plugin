#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-027-drawio-w031-regression-guard.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-063 (regression guard drawio)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (семантика W031 сохраняется:
# обобщение check_diagrams на членство в diagram_set не меняет поведение для drawio; ADR-0024 Решение 1)
# Проверка: существующий ac-015-diagram-broken.sh проходит — семантика W031 (drawio) не тронута
# Warden (зелёный при рождении, 99201c0): drawio-проверка существует и работает сегодня;
# ассерт обязан остаться зелёным после обобщения check_diagrams на mermaid/plant-uml/bpmn.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

if ! bash "$SCRIPT_DIR/ac-015-diagram-broken.sh" >/dev/null 2>&1; then
  echo "  FAIL: AC-063 — семантика W031 (drawio) регрессировала: ac-015-diagram-broken.sh красный; запусти его напрямую для деталей" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-027: AC-063 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-027: AC-063 — regression guard drawio (ac-015) зелёный"
