#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-009-section-index-resolves.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-009 (FR-080, FR-082)
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 1
# Природа: живой контракт — КРАСНЫЙ на момент создания. Ссылка `[X](section/_index)` (без
#   `.md`) на существующий `section/_index.md` — второй шаг инференса FR-082
#   (`target + ".md"`) ещё не реализован, сегодня буквальный `.exists()` не находит файл.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/section-index-explicit"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -ne 0 ]; then
  echo "  FAIL: AC-009 — ссылка [X](section/_index) на существующий section/_index.md обязана резолвиться (exit=0)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -qi 'битая\|broken'; then
  echo "  FAIL: AC-009 — вывод не должен упоминать битую/broken ссылку на 'section/_index' после инференса расширения" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-009: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-009: ссылка на раздел (явный _index, без .md) резолвится"
