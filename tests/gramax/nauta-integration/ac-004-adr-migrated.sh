#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-004-adr-migrated.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-3, FR-5
# AC coverage:
#   AC-3 → ADR переехали, docs/adr/ отсутствует
#   AC-7 → каждая статья объявляет «Тип контента»
#   AC-8 → статусы совпадают с реестром до переезда

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0
ADR_DIR="content/00-project/adr"

assert_dir_not_exists "docs/adr" "AC-3: docs/adr должен быть пуст и удалён"
assert_dir_exists "$ADR_DIR" "AC-3: ADR должны переехать в content/00-project/adr"
assert_file_exists "$ADR_DIR/_index.md" "C1: раздел ADR должен иметь _index.md"
assert_file_exists "content/00-project/_index.md" "C1: 00-project должен иметь _index.md"

for n in 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010; do
  f=$(find "$ADR_DIR" -maxdepth 1 -name "${n}-*.md" 2>/dev/null | head -1)
  if [ -z "$f" ]; then
    echo "  FAIL: AC-3: ADR-$n не найден в $ADR_DIR" >&2
    FAIL=$((FAIL + 1))
    continue
  fi
  assert_grep "$f" "Тип контента" "AC-7: $n объявляет «Тип контента»"
  assert_grep "$f" "value: [ADR]" "AC-7: $n имеет тип ADR"
done

# AC-8: статусы из реестра docs/adr/README.md на момент переезда.
check_status() {
  local n="$1" expected="$2"
  local f
  f=$(find "$ADR_DIR" -maxdepth 1 -name "${n}-*.md" 2>/dev/null | head -1)
  [ -z "$f" ] && return
  if ! grep -qF "value: [$expected]" "$f"; then
    echo "  FAIL: AC-8: ADR-$n должен иметь статус $expected" >&2
    FAIL=$((FAIL + 1))
  fi
}

check_status 0001 Superseded
check_status 0002 Historical
check_status 0003 Historical
check_status 0004 Superseded
check_status 0005 Superseded
check_status 0006 Accepted
check_status 0007 Superseded
check_status 0008 Accepted
check_status 0009 Accepted
check_status 0010 Accepted

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-004: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-004: 10 ADR мигрированы с корректными статусами"
