#!/usr/bin/env bash
# AC-003: mermaid в Markdown-syntax → fenced ```mermaid...``` блок вставляется в md
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md (AC-002, FR-001, FR-003, FR-004)
# ADR: docs/adr/0005-save-flow-script-api-contract.md (раздел 6: вставка ссылки)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-002 из spec: mermaid в каталоге с syntax:Markdown → fenced ```mermaid block в md-файле

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

# Arrange: каталог с syntax: Markdown
mkdir -p "$TMPDIR_TEST/docs/auth"
cp "$SCRIPT_DIR/fixtures/md-syntax/.doc-root.yaml" "$TMPDIR_TEST/docs/.doc-root.yaml"
cat > "$TMPDIR_TEST/docs/auth/login-flow.md" <<'EOF'
# Login Flow
EOF

# Arrange: входной DSL (готовый, без LLM)
MERMAID_DSL="flowchart TD
    A[User] --> B{Auth}
    B -->|ok| C[Dashboard]
    B -->|fail| D[Error]"

# Act: вставить fenced mermaid блок в md
bash "$INSERT_SCRIPT" \
  --target "$TMPDIR_TEST/docs/auth/login-flow.md" \
  --syntax Markdown \
  --mermaid-dsl "$MERMAID_DSL"

# Assert: md-файл содержит fenced mermaid блок
assert_grep "$TMPDIR_TEST/docs/auth/login-flow.md" '```mermaid' \
  "md должен содержать открывающий fenced mermaid блок"
assert_grep "$TMPDIR_TEST/docs/auth/login-flow.md" 'flowchart TD' \
  "md должен содержать DSL контент"
# Закрывающий тег (просто тройные бэктики присутствуют несколько раз)
BACKTICK_COUNT=$(grep -c '```' "$TMPDIR_TEST/docs/auth/login-flow.md" || true)
if [ "$BACKTICK_COUNT" -lt 2 ]; then
  echo "FAIL: md должен содержать и открывающий и закрывающий fenced блок (минимум 2 тройных бэктика)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-003-mermaid-fenced — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-003-mermaid-fenced"
