#!/usr/bin/env bash
# tests/gramax/docs-migration/ac-012-fast-gate-green.sh
# Требование: content/30-requirements/2026-11-17-docs-layout-inversion.md, AC-012 (NFR-004).
# ADR: content/00-project/adr/0021-docs-layout-inversion.md, Решение 7 — каждый коммит
# цепочки обязан держать check.sh --fast зелёным.
# КОНТРАКТ: bash scripts/check.sh --fast завершается нулём.
# ОСТАНОВ ВЕТКИ (зафиксирован в at-design.md, раздел «Остановы»): AC-012 в дереве
# до миграции ЗЕЛЁНЫЙ ПО РОЖДЕНИЮ — NFR-004 требует зелёный --fast на КАЖДОМ коммите,
# включая текущий (проверено на 8b2db0b: rc=0). Принудительно красить честный зелёный
# запретено методологией (red is the default, но green-born = warden, never forced red);
# требование брифа «каждый stub красный сейчас» для AC-012 неисполнимо честно.
# Назначение stub'а — warden на время цепочки Dev: если любой из коммитов A…D3 сломает
# быстрый гейт, этот тест ловит это в моменте.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT" || exit 1

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAIL=0

fail() {
  printf "  ${RED}FAIL:${NC} %s\n" "$1" >&2
  FAIL=$((FAIL + 1))
}

OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT
if ! bash scripts/check.sh --fast >"$OUT" 2>&1; then
  fail "AC-012/NFR-004: bash scripts/check.sh --fast завершился не нулём — цепочка миграции прошла через красное состояние:"
  tail -25 "$OUT" >&2
fi

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}[FAIL]${NC} ac-012: %d assertion(s) failed\n" "$FAIL" >&2
  exit 1
fi
# shellcheck disable=SC2059  # color codes in the format string are the intended output styling
printf "${GREEN}[PASS]${NC} ac-012: check.sh --fast зелёный (NFR-004 держится)\n"
exit 0
