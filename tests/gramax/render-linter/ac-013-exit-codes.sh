#!/usr/bin/env bash
# tests/gramax/render-linter/ac-013-exit-codes.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-013 (FR-113, NFR-001)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 8
# Проверка: каталог без ERROR, но с WARN → exit 0; каталог с ERROR → exit 1.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# --- без ERROR, с WARN → exit 0 ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$SCRIPT_DIR/fixtures/ac-013-warn-dir" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "0" "AC-013: каталог без ERROR (только WARN) → exit 0"

# --- с ERROR → exit 1 ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$SCRIPT_DIR/fixtures/ac-013-error-dir" 2>&1); then
  RC=0
else
  RC=$?
fi
assert_eq "$RC" "1" "AC-013: каталог с ERROR → exit 1"

# --- --errors-only: WARN-вывод подавляется целиком (в т.ч. заголовок «WARN path») ---
# Задокументированное намерение check.sh/pre-commit.sh: «--errors-only не спамит pre-commit».
# До фикса печатался голый заголовок «WARN path» без текста; теперь warn-only файлы молчат.
OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$SCRIPT_DIR/fixtures/ac-013-warn-dir" --errors-only 2>&1)
if printf '%s\n' "$OUT" | grep -qiE 'warn'; then
  echo "  FAIL: AC-013 — --errors-only должен подавлять WARN-вывод целиком (в т.ч. заголовок)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-013: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-013: exit 0 при WARN, exit 1 при ERROR"
