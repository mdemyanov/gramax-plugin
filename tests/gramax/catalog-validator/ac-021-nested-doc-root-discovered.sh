#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-021-nested-doc-root-discovered.sh
# Требование: content/30-requirements/2026-08-13-doc-root-discovery-contract.md AC-036 (FR-120)
# ADR: content/00-project/adr/0020-doc-root-recursive-discovery.md, Решение 1
# Природа: живой контракт — КРАСНЫЙ на момент создания.
#   Регресс-якорь инцидента 2026-08-13: до FR-120 валидатор читает только root/.doc-root.yaml,
#   битый вложенный examples/project-example/content/.doc-root.yaml даёт exit 0.
#   После FR-120 вложенный root обнаруживается и валидируется полным suite'ом → exit ≠ 0,
#   в выводе — путь вложенного файла.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/nested-doc-root-discovery"

if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1); then
  EXIT=0
else
  EXIT=$?
fi

if [ "$EXIT" -eq 0 ]; then
  echo "  FAIL: AC-036 — вложенный битый examples/project-example/content/.doc-root.yaml (незакавыченный title: {{PROJECT_NAME}}) обязан давать ненулевой код возврата (FR-120, регресс-якорь инцидента 2026-08-13)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -q "examples/project-example/content/.doc-root.yaml"; then
  echo "  FAIL: AC-036 — в выводе обязан фигурировать путь вложенного .doc-root.yaml (валидатор валидирует каждый найденный root)" >&2
  echo "  --- вывод валидатора ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-021: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-021: вложенный .doc-root.yaml обнаруживается и валидируется как отдельный root"
