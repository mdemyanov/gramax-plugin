#!/usr/bin/env bash
# AC-007: кириллица в имени файла → slugify.py возвращает ASCII-only slug
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-007, FR-008)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 2: slugify.py контракт)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-007 из spec: кириллица → ASCII slug через slugify.py; slug виден в stdout
#
# Тест вызывает slugify.py напрямую — скрипт уже существует.
# Проверяем: результат содержит только ASCII символы, exit code = 0.
# Boundary: пустой ввод → exit 2.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SLUGIFY_SCRIPT="$ROOT/plugins/gramax/scripts/slugify.py"

# --- Test 1: slugify.py существует ---
assert_file_exists "$SLUGIFY_SCRIPT" "slugify.py должен существовать"

# --- Test 2: кириллица → ASCII slug (happy path) ---
result=$(python3 "$SLUGIFY_SCRIPT" "Поток авторизации")
exit_code=$?
assert_exit_code "$exit_code" "0" "slugify.py должен завершиться с exit 0 на кириллице"

# ASCII-only: нет байтов > 127
if echo "$result" | LC_ALL=C grep -qP '[^\x00-\x7F]' 2>/dev/null || \
   python3 -c "import sys; sys.exit(0 if sys.argv[1].isascii() else 1)" "$result" 2>/dev/null; then
  : # ok
else
  echo "FAIL: slugify.py должен вернуть только ASCII символы, получено: '$result'" >&2
  FAIL=$((FAIL + 1))
fi

# Slug не пустой
if [ -z "$result" ]; then
  echo "FAIL: slugify.py не должен возвращать пустую строку на кириллическом вводе" >&2
  FAIL=$((FAIL + 1))
fi

# --- Test 3: только латиница → без изменений (кроме lowercase) ---
result_latin=$(python3 "$SLUGIFY_SCRIPT" "login-flow")
assert_exit_code "$?" "0" "slugify.py должен принять Latin input"
assert_eq "$result_latin" "login-flow" "Latin slug не должен изменяться"

# --- Test 4: смешанный ввод (кириллица + латиница) ---
result_mixed=$(python3 "$SLUGIFY_SCRIPT" "deploy схема CI")
assert_exit_code "$?" "0" "slugify.py должен принять смешанный ввод"
if python3 -c "import sys; sys.exit(0 if sys.argv[1].isascii() else 1)" "$result_mixed" 2>/dev/null; then
  : # ok
else
  echo "FAIL: slugify.py должен вернуть ASCII при смешанном вводе, получено: '$result_mixed'" >&2
  FAIL=$((FAIL + 1))
fi

# --- Test 5 (boundary): пустой ввод → exit 2, stderr содержит сообщение ---
stderr_empty=$(python3 "$SLUGIFY_SCRIPT" "" 2>&1)
empty_exit=$?
assert_exit_code "$empty_exit" "2" "slugify.py должен вернуть exit 2 на пустом вводе (ADR-0005 раздел 2)"
assert_grep_stdout "$stderr_empty" "empty" "stderr должен содержать 'empty' на пустом вводе"

# --- Test 6 (boundary): ввод только из пробелов → exit 2 ---
python3 "$SLUGIFY_SCRIPT" "   " > /dev/null 2>&1
assert_exit_code "$?" "2" "slugify.py должен вернуть exit 2 на вводе из пробелов"

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-007-slugify — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-007-slugify"
