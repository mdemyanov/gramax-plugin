#!/usr/bin/env bash
# AC-010: ссылка на диаграмму вставляется в md в корректном syntax (XML или Markdown)
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-005, FR-003, FR-004)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 6: форматы вставки)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-005 из spec: drawio в XML-syntax → <Image src="...svg" /> вставляется в md
#   Дополнительно: Markdown-syntax → ![...](....svg) вставляется в md

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

INSERT_SCRIPT="$ROOT/plugins/gramax/scripts/insert_diagram_ref.sh"

assert_file_exists "$INSERT_SCRIPT" "insert_diagram_ref.sh должен существовать"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# --- Test 1: XML-syntax → <Image src="..." /> ---
mkdir -p "$TMPDIR_TEST/xml"
cat > "$TMPDIR_TEST/xml/deploy.md" <<'EOF'
# Deploy Architecture
EOF

bash "$INSERT_SCRIPT" \
  --target "$TMPDIR_TEST/xml/deploy.md" \
  --syntax XML \
  --svg-name "deploy.svg" \
  --alt "Deploy diagram"

assert_grep "$TMPDIR_TEST/xml/deploy.md" '<Image src="deploy.svg"' \
  "XML-syntax: md должен содержать <Image src='deploy.svg'"
assert_grep "$TMPDIR_TEST/xml/deploy.md" '/>' \
  "XML-syntax: <Image> тег должен быть самозакрывающимся"

# --- Test 2: Markdown-syntax → ![...](....svg) ---
mkdir -p "$TMPDIR_TEST/md"
cat > "$TMPDIR_TEST/md/deploy.md" <<'EOF'
# Deploy Architecture
EOF

bash "$INSERT_SCRIPT" \
  --target "$TMPDIR_TEST/md/deploy.md" \
  --syntax Markdown \
  --svg-name "deploy.svg" \
  --alt "Deploy diagram"

assert_grep "$TMPDIR_TEST/md/deploy.md" '![' \
  "Markdown-syntax: md должен содержать markdown image syntax !["
assert_grep "$TMPDIR_TEST/md/deploy.md" '(deploy.svg)' \
  "Markdown-syntax: ссылка должна указывать на deploy.svg"

# --- Test 3: вставка в конец файла (дефолт по ADR-0005 раздел 6) ---
assert_grep "$TMPDIR_TEST/xml/deploy.md" '# Deploy Architecture' \
  "существующий контент страницы должен сохраниться"

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-010-md-insert — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-010-md-insert"
