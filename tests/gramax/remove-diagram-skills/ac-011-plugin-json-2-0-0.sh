#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-011-plugin-json-2-0-0.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# ADR: docs/adr/0008-drop-internal-drawio-skills.md Решение 1
# AC coverage:
#   AC-011 → plugins/gramax/.claude-plugin/plugin.json содержит "version": "2.0.0"
#             description не содержит diagram-on-demand, /gramax:diagrams как skills
#
# TDD stub: должен ПАДАТЬ пока Dev не обновит plugin.json.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"

assert_file_exists "$PLUGIN_JSON" \
  "AC-011: plugins/gramax/.claude-plugin/plugin.json must exist"

# Validate it is parseable JSON
if ! python3 -c "import json; json.load(open('$PLUGIN_JSON'))" 2>/dev/null; then
  echo "  FAIL: AC-011: plugin.json is not valid JSON" >&2
  FAIL=$((FAIL + 1))
fi

# Version must be 2.0.0
ACTUAL_VERSION="$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d.get('version','MISSING'))" 2>/dev/null || echo "PARSE_ERROR")"
assert_eq "$ACTUAL_VERSION" "2.0.0" \
  "AC-011: plugin.json version must be '2.0.0'"

# Description must not mention removed skills
DESCRIPTION="$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d.get('description',''))" 2>/dev/null || echo "")"
if echo "$DESCRIPTION" | grep -qE "diagram-on-demand|gramax:diagrams"; then
  echo "  FAIL: AC-011: plugin.json description still mentions removed skills: $DESCRIPTION" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-011: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-011: plugin.json has version 2.0.0 and clean description"
