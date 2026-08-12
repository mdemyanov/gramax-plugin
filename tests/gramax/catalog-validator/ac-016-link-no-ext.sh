#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-016-link-no-ext.sh
# Требование: docs/superpowers/specs/2026-08-12-healthcheck-port-design.md — no-ext resolution
# Проверка: [link](./other) где other.md существует → OK (no error)
#           [link](./nonexistent) где ничего нет → битая ссылка (error)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

# no-ext OK: ссылка без .md на существующий файл
FIXTURE_OK="$SCRIPT_DIR/fixtures/gramax-fixtures/link-no-ext-ok"
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE_OK" 2>&1); then
  EXIT_OK=0
else
  EXIT_OK=$?
fi
if [ "$EXIT_OK" -ne 0 ]; then
  echo "  FAIL: no-ext OK — ссылка [other](./other) где other.md существует не должна давать ошибку (exit=$EXIT_OK)" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if echo "$OUT" | grep -qiE 'битая ссылка|broken link'; then
  echo "  FAIL: no-ext OK — ссылка [other](./other) где other.md существует не должна давать broken link" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

# no-ext broken: ссылка на несуществующий файл
FIXTURE_BROKEN="$SCRIPT_DIR/fixtures/gramax-fixtures/link-no-ext-broken"
if OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py "$FIXTURE_BROKEN" 2>&1); then
  EXIT_BROKEN=0
else
  EXIT_BROKEN=$?
fi
if [ "$EXIT_BROKEN" -eq 0 ]; then
  echo "  FAIL: no-ext broken — ссылка на несуществующий файл должна давать ошибку" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi
if ! echo "$OUT" | grep -qiE 'битая ссылка|broken link'; then
  echo "  FAIL: no-ext broken — ссылка на несуществующий файл должна давать broken link" >&2
  echo "  --- вывод ---" >&2
  echo "$OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-016: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-016: no-ext link resolution работает корректно"
