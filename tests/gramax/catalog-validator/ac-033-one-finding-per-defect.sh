#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-033-one-finding-per-defect.sh
# Требование: docs/30-requirements/2026-11-18-validators-error-check-parity-requirement.md — AC-069 (FR-152, NFR-067)
# Дизайн: docs/40-architecture/2026-11-18-validators-parity-design.md (демаркация структурная:
# диаграммные теги входят в known_tags → W034 молчит, одна находка W031 на дефект; ADR-0024 Решения 1/4)
# Проверка: одна битая <mermaid path="./missing.mmd"/> → ровно одно упоминание 'missing.mmd'
# Red on 99201c0 (2026-11-18): цель mermaid не извлекается парсером и не проверяется —
# упоминаний 'missing.mmd' ноль (W034 эхолит только имя тега <mermaid>, без пути).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/validators-parity/one-finding"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

COUNT=$(echo "$OUT" | grep -cF 'missing.mmd' || true)
assert_eq "$COUNT" "1" "AC-069 — одна находка на дефект: упоминаний 'missing.mmd' в выводе должно быть ровно 1 (FR-152, без дубля от W034)"

if [ "$FAIL" -gt 0 ]; then
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  fail_msg "ac-033: AC-069 — $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-033: AC-069 — битая цель даёт ровно одну находку"
