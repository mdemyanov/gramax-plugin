#!/usr/bin/env bash
# tests/gramax/render-linter/ac-012-dedup-w034.sh
# Требование: content/30-requirements/2026-08-12-render-killer-linter.md — AC-012 (FR-114)
# ADR: content/00-project/adr/0019-render-killer-linter.md, Решение 3
# Проверка: validate_structure.py НЕ флагает <th> как W034; validate_render.py даёт по нему
#           ERROR. Итого по гейту — ровно одна находка на <th> (BR-004).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DIR="$SCRIPT_DIR/fixtures/ac-012-dedup-dir"

# --- validate_structure.py: W034 молчит по <th> (тег в known = drawio ∪ killerTags ∪ allowlistedTags) ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$DIR" 2>&1); then
  RC=0
else
  RC=$?
fi

if printf '%s\n' "$OUT" | grep -q '<th>'; then
  echo "  FAIL: AC-012 — validate_structure.py не должен флагать <th> как W034 (одна находка по гейту)" >&2
  echo "  --- вывод validate_structure.py ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

# --- validate_render.py: ERROR по тому же <th> ---
if OUT2=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$DIR" 2>&1); then
  RC2=0
else
  RC2=$?
fi

assert_eq "$RC2" "1" "AC-012: validate_render.py обязан давать exit 1 по <th>"
if ! printf '%s\n' "$OUT2" | grep -q 'ERROR'; then
  echo "  FAIL: AC-012 — validate_render.py обязан выдавать ERROR по <th>" >&2
  echo "  --- вывод validate_render.py ---" >&2
  echo "$OUT2" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-012: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-012: W034 молчит по <th>, рендер-линтер даёт ERROR — одна находка на дефект"
