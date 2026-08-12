#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-008-no-extension-resolves.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-008 (FR-080, FR-082)
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 1
# Архитектура: content/40-architecture/2026-08-13-link-form-contract-design.md, «Бриф для Dev» п.1
# Природа: живой контракт — КРАСНЫЙ на момент создания. `_collect_links`
#   (plugins/gramax/scripts/validate_structure.py:286-313) резолвит цель ссылки буквально
#   (`(md.parent / target).resolve()`), без попытки `target + ".md"` — ссылка `[X](doc)` на
#   существующий `doc.md` сегодня ошибочно считается битой. Закрывает FR-082/DEV-фаза
#   «Резолвер» из брифа для Dev.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/no-extension"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -ne 0 ]; then
  echo "  FAIL: AC-008 — ссылка [X](doc) на существующий doc.md обязана резолвиться (exit=0), инференс расширения .md ещё не реализован (FR-082)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -qi 'битая\|broken'; then
  echo "  FAIL: AC-008 — вывод не должен упоминать битую/broken ссылку на 'doc' после инференса расширения" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-008: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-008: ссылка без расширения резолвится через инференс .md"
