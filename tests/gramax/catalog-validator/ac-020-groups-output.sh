#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-020-groups-output.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — --groups
# Проверка: флаг --groups выводит группированный вывод с заголовками групп

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
FIXTURE="$SCRIPT_DIR/fixtures/gramax-fixtures/broken-image"

OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" --groups 2>&1) || true

if ! echo "$OUT" | grep -qE '\[images\]'; then
  echo "  FAIL: --groups вывод должен содержать '[images]' заголовок группы" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if ! echo "$OUT" | grep -qE 'incorrects-paths'; then
  echo "  FAIL: --groups вывод должен содержать 'incorrects-paths' (название группы из CatalogErrorGroups)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

# Без --groups вывод НЕ должен содержать [images] (плоский формат)
OUT_FLAT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE" 2>&1) || true
if echo "$OUT_FLAT" | grep -qE '^\[images\]'; then
  echo "  FAIL: без --groups вывод не должен содержать '[images]' заголовок (плоский формат по умолчанию)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-020: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-020: --groups вывод работает корректно"
