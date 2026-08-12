#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-011-genuinely-broken-link-detected.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-011 (FR-082, NFR-001)
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 1
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. Ни `missing-target`, ни
#   `missing-target.md`, ни `missing-target/_index.md` не существуют — все три шага
#   инференса FR-082 промахиваются, как и сегодняшний буквальный резолв. Тест — прямая
#   проверка safeguard-инварианта требования: «Расширение резолвера ... строго
#   ослабляющее: не может превратить генуинно битую ссылку в «ок»» — обязан оставаться
#   зелёным и до, и после реализации FR-082 (иначе резолвер перестал бы ловить настоящие
#   дефекты).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/genuinely-missing"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-011 — ссылка на missing-target обязана оставаться битой (ни цель, ни цель.md, ни цель/_index.md не существуют) — расширение резолвера не должно ослаблять детекцию настоящих дефектов" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -q 'missing-target'; then
  echo "  FAIL: AC-011 — сообщение об ошибке обязано называть конкретную ссылку 'missing-target'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-011: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-011: генуинно битая ссылка остаётся ошибкой после инференса"
