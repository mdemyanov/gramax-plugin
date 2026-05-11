#!/usr/bin/env bash
# AC-004: mermaid в XML-syntax → <mermaid>...</mermaid> теги вставляются в md
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-001, FR-001, FR-003, FR-004)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 6: формат XML-syntax)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-001 из spec: при запросе mermaid с syntax:XML → в md вставляется <mermaid>...</mermaid> блок

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

FIND_SCRIPT="$ROOT/plugins/gramax/scripts/find_doc_root.sh"
INSERT_SCRIPT="$ROOT/plugins/gramax/scripts/insert_diagram_ref.sh"

# Предварительные проверки существования
assert_file_exists "$FIND_SCRIPT" "find_doc_root.sh должен существовать"
assert_file_exists "$INSERT_SCRIPT" "insert_diagram_ref.sh должен существовать"

TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

# Arrange: каталог с syntax: XML
mkdir -p "$TMPDIR_TEST/docs/auth"
cp "$SCRIPT_DIR/fixtures/xml-syntax/.doc-root.yaml" "$TMPDIR_TEST/docs/.doc-root.yaml"
cat > "$TMPDIR_TEST/docs/auth/login-flow.md" <<'EOF'
# Login Flow
EOF

# Arrange: входной DSL
MERMAID_DSL="flowchart TD
    A[User] --> B{Auth}
    B -->|ok| C[Dashboard]
    B -->|fail| D[Error]"

# Act: вставить XML-syntax mermaid ссылку
bash "$INSERT_SCRIPT" \
  --target "$TMPDIR_TEST/docs/auth/login-flow.md" \
  --syntax XML \
  --mermaid-dsl "$MERMAID_DSL"

# Assert: md-файл содержит <mermaid> теги, НЕ содержит fenced ```mermaid
assert_grep "$TMPDIR_TEST/docs/auth/login-flow.md" '<mermaid>' \
  "XML-syntax должен вставить открывающий тег <mermaid>"
assert_grep "$TMPDIR_TEST/docs/auth/login-flow.md" '</mermaid>' \
  "XML-syntax должен вставить закрывающий тег </mermaid>"
assert_not_grep_stdout "$(cat "$TMPDIR_TEST/docs/auth/login-flow.md")" '```mermaid' \
  "XML-syntax не должен вставлять fenced block"
assert_grep "$TMPDIR_TEST/docs/auth/login-flow.md" 'flowchart TD' \
  "md должен содержать DSL контент внутри тегов"

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-004-mermaid-xml — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-004-mermaid-xml"
