#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-011-marketplace-no-claude-mermaid.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-011/FR-010 → .claude-plugin/marketplace.json — массив «plugins» не содержит
#                   элемент с name == "claude-mermaid"
#
# TDD stub: ПАДАЕТ пока Dev не уберёт claude-mermaid entry из marketplace.json.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"

assert_file_exists "$MARKETPLACE" \
  "AC-011: .claude-plugin/marketplace.json must exist"

if [ -f "$MARKETPLACE" ]; then
  # Validate JSON is parseable
  if ! python3 -c "import json, sys; json.load(open('$MARKETPLACE'))" 2>/dev/null; then
    echo "  FAIL: AC-011: .claude-plugin/marketplace.json is not valid JSON" >&2
    FAIL=$((FAIL + 1))
  else
    # Check no claude-mermaid in plugins array
    RESULT=$(python3 -c "
import json, sys
with open('$MARKETPLACE') as f:
    d = json.load(f)
plugins = d.get('plugins', [])
names = [p.get('name','') for p in plugins]
if 'claude-mermaid' in names:
    print('FOUND')
else:
    print('OK')
")
    if [ "$RESULT" = "FOUND" ]; then
      echo "  FAIL: AC-011: marketplace.json still has 'claude-mermaid' in plugins array" >&2
      python3 -c "import json; d=json.load(open('$MARKETPLACE')); [print('  ',p) for p in d.get('plugins',[])]" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-011: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-011: marketplace.json plugins array has no claude-mermaid entry"
