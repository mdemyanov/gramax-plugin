#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-011b-no-double-md-extension.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md — edge case из
#   content/40-architecture/2026-08-13-link-form-contract-design.md, «Контракт с
#   QA-author» → «Edge cases»: «Цель уже оканчивается на `.md`, но файла нет ... инференс
#   НЕ должен пытаться добавить второе `.md` (AC-011 не должен «случайно починиться»)».
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 1 («Бриф для Dev» п.1:
#   «если target не оканчивается на .md — попробовать литерал → target+.md → .../_index.md;
#   ИНАЧЕ (либо ничего не найдено) — вернуть литеральный resolve(), как сегодня»).
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. `missing.md` уже несёт
#   расширение — по брифу для Dev инференс к таким целям не применяется вовсе, поведение
#   идентично сегодняшнему буквальному резолву и до, и после FR-082.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/already-md-missing"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-011 edge — ссылка [X](missing.md) на несуществующий файл обязана оставаться битой; инференс не должен пытаться найти 'missing.md.md'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -q 'missing.md'; then
  echo "  FAIL: AC-011 edge — сообщение об ошибке обязано называть конкретную ссылку 'missing.md'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if echo "$OUT" | grep -q 'missing.md.md'; then
  echo "  FAIL: AC-011 edge — резолвер не должен пытаться подставлять второе расширение 'missing.md.md'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-011b: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-011b: цель, уже оканчивающаяся на .md, не получает второго .md от инференса"
