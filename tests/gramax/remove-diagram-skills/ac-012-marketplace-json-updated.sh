#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-012-marketplace-json-updated.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# ADR: docs/adr/0008-drop-internal-drawio-skills.md Решение 7
# AC coverage:
#   AC-012 → .claude-plugin/marketplace.json:
#             metadata.version = "2.0.0"
#             plugins[gramax].description не содержит diagram-on-demand или /gramax:diagrams
#             description упоминает делегирование drawio внешнему плагину
#
# TDD stub: должен ПАДАТЬ пока Dev не обновит marketplace.json.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

MARKETPLACE_JSON="$ROOT/.claude-plugin/marketplace.json"

assert_file_exists "$MARKETPLACE_JSON" \
  "AC-012: .claude-plugin/marketplace.json must exist"

# Validate parseable JSON
if ! python3 -c "import json; json.load(open('$MARKETPLACE_JSON'))" 2>/dev/null; then
  echo "  FAIL: AC-012: marketplace.json is not valid JSON" >&2
  FAIL=$((FAIL + 1))
fi

# metadata.version must be 2.0.0
META_VERSION="$(python3 -c "
import json
d = json.load(open('$MARKETPLACE_JSON'))
print(d.get('metadata', {}).get('version', 'MISSING'))
" 2>/dev/null || echo "PARSE_ERROR")"
assert_eq "$META_VERSION" "2.0.0" \
  "AC-012: marketplace.json metadata.version must be '2.0.0'"

# gramax plugin description must not mention removed skills
GRAMAX_DESC="$(python3 -c "
import json
d = json.load(open('$MARKETPLACE_JSON'))
plugins = d.get('plugins', [])
gramax = next((p for p in plugins if p.get('name') == 'gramax'), None)
if gramax is None:
    # try dict form
    gramax = d.get('plugins', {}).get('gramax', {})
print(gramax.get('description', '') if isinstance(gramax, dict) else '')
" 2>/dev/null || echo "")"

if echo "$GRAMAX_DESC" | grep -qE "diagram-on-demand"; then
  echo "  FAIL: AC-012: marketplace.json gramax description still contains 'diagram-on-demand': $GRAMAX_DESC" >&2
  FAIL=$((FAIL + 1))
fi

# Boundary: also check metadata-level description
META_DESC="$(python3 -c "
import json
d = json.load(open('$MARKETPLACE_JSON'))
print(d.get('metadata', {}).get('description', ''))
" 2>/dev/null || echo "")"

if echo "$META_DESC" | grep -qE "diagram-on-demand"; then
  echo "  FAIL: AC-012: marketplace.json metadata.description still contains 'diagram-on-demand': $META_DESC" >&2
  FAIL=$((FAIL + 1))
fi

# Positive: description must mention external delegation (Agents365-ai or drawio-skill)
if ! echo "$GRAMAX_DESC$META_DESC" | grep -qE "Agents365-ai|drawio-skill|внешний"; then
  echo "  FAIL: AC-012: marketplace.json descriptions must mention external drawio delegation (Agents365-ai or внешний)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-012: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-012: marketplace.json has version 2.0.0 and updated descriptions"
