#!/usr/bin/env bash
# AC-002: find_doc_root.sh находит .doc-root.yaml вверх по дереву каталогов
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (FR-003, FR-006, AC-006)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 1: find_doc_root.sh)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-002 (find_doc_root.sh contract):
#     - скрипт существует в plugins/gramax/scripts/
#     - вызов с файлом в поддиректории → находит .doc-root.yaml в родителе
#     - вызов с файлом в корне каталога → находит .doc-root.yaml рядом
#     - вызов с файлом без .doc-root.yaml в дереве → exit 1
#
# Соответствует AC-006 из spec (fallback при отсутствии .doc-root.yaml — тестируется в ac-006)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

FIND_SCRIPT="$ROOT/plugins/gramax/scripts/find_doc_root.sh"

# --- Test 1: скрипт существует ---
assert_file_exists "$FIND_SCRIPT" "find_doc_root.sh должен существовать в plugins/gramax/scripts/"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# --- Test 2: находит .doc-root.yaml в родительской директории ---
mkdir -p "$TMPDIR_TEST/docs/auth"
cp "$SCRIPT_DIR/fixtures/xml-syntax/.doc-root.yaml" "$TMPDIR_TEST/docs/.doc-root.yaml"
touch "$TMPDIR_TEST/docs/auth/login-flow.md"

result=$(bash "$FIND_SCRIPT" "$TMPDIR_TEST/docs/auth/login-flow.md")
exit_code=$?
assert_exit_code "$exit_code" "0" "find_doc_root.sh должен найти .doc-root.yaml в родителе (exit 0)"
assert_eq "$result" "$TMPDIR_TEST/docs/.doc-root.yaml" "find_doc_root.sh должен вернуть путь к .doc-root.yaml"

# --- Test 3: находит .doc-root.yaml в той же директории ---
mkdir -p "$TMPDIR_TEST/repo"
cp "$SCRIPT_DIR/fixtures/md-syntax/.doc-root.yaml" "$TMPDIR_TEST/repo/.doc-root.yaml"
touch "$TMPDIR_TEST/repo/page.md"

result=$(bash "$FIND_SCRIPT" "$TMPDIR_TEST/repo/page.md")
assert_exit_code "$?" "0" "find_doc_root.sh должен найти .doc-root.yaml рядом с файлом"
assert_eq "$result" "$TMPDIR_TEST/repo/.doc-root.yaml" "путь должен быть к .doc-root.yaml рядом"

# --- Test 4: возвращает exit 1 при отсутствии .doc-root.yaml в дереве ---
mkdir -p "$TMPDIR_TEST/notree/subdir"
touch "$TMPDIR_TEST/notree/subdir/page.md"
bash "$FIND_SCRIPT" "$TMPDIR_TEST/notree/subdir/page.md" > /dev/null 2>&1
assert_exit_code "$?" "1" "find_doc_root.sh должен вернуть exit 1 если .doc-root.yaml не найден"

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-002-find-doc-root — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-002-find-doc-root"
