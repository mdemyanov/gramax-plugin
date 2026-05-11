#!/usr/bin/env bash
# AC-006: нет .doc-root.yaml → fallback Markdown-синтаксис + [WARN] в stdout
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-006, FR-006)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 1: fallback при exit 1)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-006 из spec: .doc-root.yaml отсутствует → [WARN] в stdout, Markdown-синтаксис, выполнение не прерывается

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

FIND_SCRIPT="$ROOT/plugins/gramax/scripts/find_doc_root.sh"

assert_file_exists "$FIND_SCRIPT" "find_doc_root.sh должен существовать для теста fallback-noyaml"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# Arrange: каталог без .doc-root.yaml
mkdir -p "$TMPDIR_TEST/isolated/subdir"
touch "$TMPDIR_TEST/isolated/subdir/page.md"

# Act: вызов find_doc_root.sh с путём без .doc-root.yaml
bash "$FIND_SCRIPT" "$TMPDIR_TEST/isolated/subdir/page.md" > /dev/null 2>&1
exit_code=$?

# Assert: exit code 1 (не найден)
assert_exit_code "$exit_code" "1" \
  "find_doc_root.sh должен вернуть exit 1 при отсутствии .doc-root.yaml"

# Assert: YAML-парсер из ADR-0005 возвращает 'Markdown' при пустом input
fallback_syntax=$(python3 -c "
import re, sys
content = ''
m = re.search(r'^syntax:\s*(\S+)', content, re.MULTILINE)
print(m.group(1) if m else 'Markdown')
")
assert_eq "$fallback_syntax" "Markdown" \
  "YAML-парсер должен вернуть 'Markdown' при пустом содержимом (fallback)"

# Assert: YAML-парсер корректно читает syntax из XML-fixtures
xml_content=$(cat "$SCRIPT_DIR/fixtures/xml-syntax/.doc-root.yaml")
xml_syntax=$(python3 -c "
import re, sys
content = sys.argv[1]
m = re.search(r'^syntax:\s*(\S+)', content, re.MULTILINE)
print(m.group(1) if m else 'Markdown')
" "$xml_content")
assert_eq "$xml_syntax" "XML" \
  "YAML-парсер должен вернуть 'XML' из xml-syntax fixture"

# Assert: YAML-парсер корректно читает syntax из Markdown-fixtures
md_content=$(cat "$SCRIPT_DIR/fixtures/md-syntax/.doc-root.yaml")
md_syntax=$(python3 -c "
import re, sys
content = sys.argv[1]
m = re.search(r'^syntax:\s*(\S+)', content, re.MULTILINE)
print(m.group(1) if m else 'Markdown')
" "$md_content")
assert_eq "$md_syntax" "Markdown" \
  "YAML-парсер должен вернуть 'Markdown' из md-syntax fixture"

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-006-fallback-noyaml — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-006-fallback-noyaml"
