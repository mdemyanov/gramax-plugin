#!/usr/bin/env bash
# tests/gramax/render-linter/ac-006-unbalanced.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-006 (FR-109)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 6
# Проверка: <note> без </note> и <tabs> без </tabs> → ERROR с именами тегов и числами.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/ac-006-unbalanced.md"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$FIXTURE" 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "1" "AC-006: несбалансированные теги обязаны давать exit 1"

if ! printf '%s\n' "$OUT" | grep -q 'Несбалансированный <note>'; then
  echo "  FAIL: AC-006 — вывод должен содержать 'Несбалансированный <note>'" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'Несбалансированный <tabs>'; then
  echo "  FAIL: AC-006 — вывод должен содержать 'Несбалансированный <tabs>'" >&2
  FAIL=$((FAIL + 1))
fi
if ! printf '%s\n' "$OUT" | grep -q 'открыто 1, закрыто 0'; then
  echo "  FAIL: AC-006 — сообщение должно содержать числа открыто/закрыто" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-006: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-006: unbalanced <note>/<tabs> → ERROR с числами открыто/закрыто, exit 1"
