#!/usr/bin/env bash
# tests/gramax/render-linter/ac-009-h1-warn.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-009 (FR-111)
# Проверка: строка `# Заголовок` в теле → WARN (не ERROR), exit 0.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-009-h1.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "0" "AC-009: H1 в теле — WARN, exit 0"

if ! printf '%s\n' "$OUT" | grep -q 'warn'; then
  echo "  FAIL: AC-009 — вывод должен содержать warn/WARN для строки с H1" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT" | grep -qE 'ERROR L[0-9]'; then
  echo "  FAIL: AC-009 — H1 не должен быть ERROR" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-009: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-009: H1 в теле → WARN, exit 0"
