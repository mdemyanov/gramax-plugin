#!/usr/bin/env bash
# tests/gramax/render-linter/ac-012-dedup-w034.sh
# Требование: docs/30-requirements/2026-08-12-render-killer-linter.md — AC-012 (FR-114)
# ADR: docs/00-project/adr/0019-render-killer-linter.md, Решение 3
# Понижение severity (адаптация без ослабления, NFR-083): запись замера
#   docs/60-implementation/acceptance/2026-11-21-render-calibration-th.md —
#   th понижен ERROR → WARN; membership th в killerTags сохранён, поэтому W034-молчание
#   validate_structure не меняется; паритетная находка рендер-линтера — warn (BR-004:
#   одна находка на дефект сохраняется).
# Проверка: validate_structure.py НЕ флагает <th> как W034; validate_render.py даёт по нему
#           warn. Итого по гейту — ровно одна находка на <th> (BR-004).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
DIR="$SCRIPT_DIR/fixtures/ac-012-dedup-dir"

# --- validate_structure.py: W034 молчит по <th> (тег в known = drawio ∪ killerTags ∪ allowlistedTags) ---
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$DIR" 2>&1); then
  : # rc 0 допустим — предмет проверки ниже: '<th>' в выводе отсутствует
else
  : # ненулевой rc здесь не ассертится — контракт проверяет вывод, не код (SC2034: RC не читается)
fi

if printf '%s\n' "$OUT" | grep -q '<th>'; then
  echo "  FAIL: AC-012 — validate_structure.py не должен флагать <th> как W034 (одна находка по гейту)" >&2
  echo "  --- вывод validate_structure.py ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

# --- validate_render.py: warn по тому же <th> (понижение 2026-11-21, NFR-083) ---
if OUT2=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_render.py "$DIR" 2>&1); then
  RC2=0
else
  RC2=$?
fi

assert_eq "$RC2" "0" "AC-012: validate_render.py даёт warn по <th> — WARN rc не красит (NFR-001)"
if ! printf '%s\n' "$OUT2" | grep -q 'warn'; then
  echo "  FAIL: AC-012 — validate_render.py обязан выдавать warn по <th>" >&2
  echo "  --- вывод validate_render.py ---" >&2
  echo "$OUT2" >&2
  FAIL=$((FAIL + 1))
fi
if printf '%s\n' "$OUT2" | grep -q 'ERROR L'; then
  echo "  FAIL: AC-012 — пониженный <th> не даёт ERROR-строк (ERROR L присутствует)" >&2
  echo "  --- вывод validate_render.py ---" >&2
  echo "$OUT2" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-012: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-012: W034 молчит по <th>, рендер-линтер даёт warn — одна находка на дефект"
