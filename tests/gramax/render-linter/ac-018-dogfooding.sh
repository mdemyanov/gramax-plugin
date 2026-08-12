#!/usr/bin/env bash
# tests/gramax/render-linter/ac-018-dogfooding.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-018 (FR-119)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 8
# Проверка: прогон линтера на собственном content/ → exit 0 (без ERROR);
#           WARN (H1 в теле) допустимы и не блокируют (BA «Открытый вопрос 3»).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py content 2>&1); then
  RC=0
else
  RC=$?
fi

assert_eq "$RC" "0" "AC-018: догфудинг на content/ → exit 0 (без ERROR; WARN допустимы)"

if [ "$FAIL" -gt 0 ]; then
  echo "  --- хвост вывода (первые 15 строк ERROR) ---" >&2
  printf '%s\n' "$OUT" | grep -E 'ERROR|FAIL' | head -15 >&2
  fail_msg "ac-018: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-018: собственный content/ проходит линтер без ERROR"
