#!/usr/bin/env bash
# tests/gramax/link-form-resolver/ac-010-doc-root-prefix-antipattern-stays-broken.sh
# Требование: content/30-requirements/2026-08-13-link-form-contract.md AC-010 (FR-081, FR-082)
# ADR: content/00-project/adr/0016-link-form-contract.md, Решение 1
# Природа: regression guard — ЗЕЛЁНЫЙ на момент создания. Цель `content/section/doc.md`
#   уже оканчивается на `.md` — по брифу для Dev (content/40-architecture/
#   2026-08-13-link-form-contract-design.md, «Бриф для Dev» п.1) инференс расширения НЕ
#   применяется к целям, уже оканчивающимся на `.md` — резолв остаётся буквальным и
#   сегодня, и после FR-082. Тест защищает NFR-001/BR-002/AC-010: расширение резолвера не
#   должно случайно начать резолвить антипаттерн повторения имени doc-root-каталога.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/doc-root-prefix-antipattern"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-010 — ссылка [X](content/section/doc.md) обязана оставаться битой (антипаттерн FR-081, реальный путь section/doc.md), расширенный резолвер не должен начать её резолвить" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qi 'content/section/doc.md'; then
  echo "  FAIL: AC-010 — сообщение об ошибке обязано называть конкретную ссылку 'content/section/doc.md'" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-010: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-010: антипаттерн (повтор имени doc-root-каталога) остаётся ошибкой"
