#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-017-link-hash.sh
# Требование: спека healthcheck-port (2026-08-12; историческая, прародитель удалён при инверсии раскладки 2026-11-17 — FR-129, ADR-0021); живой наследник темы — docs/30-requirements/2026-08-13-doc-root-discovery-contract.md — W033
# Проверка: [link](./target.md#nonexistent-section) → W033 warning
#           [link](./target.md#existing-section) → OK (no warning)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# hash broken: несуществующий заголовок
FIXTURE_BROKEN="$SCRIPT_DIR/fixtures/gramax-fixtures/link-hash-broken"
OUT_BROKEN=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE_BROKEN" 2>&1) || true

if ! echo "$OUT_BROKEN" | grep -qiE 'W033|hash-якор|hash.*anchor'; then
  echo "  FAIL: W033 — вывод должен содержать 'W033' или 'hash-якорь'" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT_BROKEN" >&2
  FAIL=$((FAIL + 1))
fi

# hash OK: существующий заголовок — не должно быть W033
FIXTURE_OK="$SCRIPT_DIR/fixtures/gramax-fixtures/link-hash-ok"
OUT_OK=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE_OK" 2>&1) || true

if echo "$OUT_OK" | grep -qi 'W033'; then
  echo "  FAIL: hash OK — ссылка на существующий заголовок не должна давать W033" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT_OK" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-017: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-017: hash-якоря проверяются корректно (W033)"
