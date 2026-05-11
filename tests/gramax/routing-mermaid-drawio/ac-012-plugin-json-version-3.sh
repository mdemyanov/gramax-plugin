#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-012-plugin-json-version-3.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# ADR: docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md (Решение 3)
# AC coverage:
#   AC-012/FR-009 → plugins/gramax/.claude-plugin/plugin.json — .version == "3.0.0"
#
# TDD stub: ПАДАЕТ пока Dev не сделает bump версии в plugin.json.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"

assert_file_exists "$PLUGIN_JSON" \
  "AC-012: plugins/gramax/.claude-plugin/plugin.json must exist"

if [ -f "$PLUGIN_JSON" ]; then
  if ! python3 -c "import json, sys; json.load(open('$PLUGIN_JSON'))" 2>/dev/null; then
    echo "  FAIL: AC-012: plugin.json is not valid JSON" >&2
    FAIL=$((FAIL + 1))
  else
    ACTUAL_VERSION=$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d.get('version','MISSING'))")
    assert_eq "$ACTUAL_VERSION" "3.0.0" \
      "AC-012: plugin.json version must be '3.0.0' (major bump for breaking change)"
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-012: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-012: plugins/gramax/.claude-plugin/plugin.json version == 3.0.0"
