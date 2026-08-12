#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-018-unsupported-markup.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — W034
# Проверка: <div>, <iframe> в markdown → W034 warning

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/gramax-fixtures/unsupported-html"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true

if ! echo "$OUT" | grep -qiE 'W034|неподдержива|unsupported'; then
  echo "  FAIL: W034 — вывод должен содержать 'W034' или 'неподдержива' или 'unsupported'" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-018: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-018: неподдерживаемая разметка обнаруживается (W034)"
