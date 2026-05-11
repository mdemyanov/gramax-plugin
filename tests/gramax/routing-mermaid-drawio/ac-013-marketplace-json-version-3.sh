#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-013-marketplace-json-version-3.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# ADR: docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md (Решение 3)
# AC coverage:
#   AC-012 (marketplace side) / FR-010 → .claude-plugin/marketplace.json — metadata.version == "3.0.0"
#   (Both plugin.json and marketplace.json must be bumped synchronously — ADR-0006)
#
# TDD stub: ПАДАЕТ пока Dev не сделает bump версии в marketplace.json.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"

assert_file_exists "$MARKETPLACE" \
  "AC-013: .claude-plugin/marketplace.json must exist"

if [ -f "$MARKETPLACE" ]; then
  if ! python3 -c "import json, sys; json.load(open('$MARKETPLACE'))" 2>/dev/null; then
    echo "  FAIL: AC-013: marketplace.json is not valid JSON" >&2
    FAIL=$((FAIL + 1))
  else
    ACTUAL_VERSION=$(python3 -c "import json; d=json.load(open('$MARKETPLACE')); print(d.get('metadata',{}).get('version','MISSING'))")
    assert_eq "$ACTUAL_VERSION" "3.0.0" \
      "AC-013: marketplace.json metadata.version must be '3.0.0' (synchronous bump with plugin.json)"
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-013: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-013: .claude-plugin/marketplace.json metadata.version == 3.0.0"
