#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-015-diagram-broken.sh
# Требование: спека healthcheck-port (2026-08-12; историческая, прародитель удалён при инверсии раскладки 2026-11-17 — FR-129, ADR-0021); живой наследник темы — docs/30-requirements/2026-08-13-doc-root-discovery-contract.md — W031
# Проверка: битая диаграмма <drawio path="./missing.drawio"/> → W031 warning

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/gramax-fixtures/broken-diagram"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if ! echo "$OUT" | grep -qiE 'W031|диаграмм|diagram'; then
  echo "  FAIL: W031 — вывод должен содержать 'W031' или 'диаграмм' или 'diagram'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-015: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-015: битая диаграмма обнаруживается (W031)"
