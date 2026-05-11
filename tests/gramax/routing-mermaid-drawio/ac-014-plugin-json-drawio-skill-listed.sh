#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-014-plugin-json-drawio-skill-listed.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-002/FR-001 → plugins/gramax/.claude-plugin/plugin.json содержит skill drawio в секции skills
#                   (Dev must add a skills array/dict declaring the drawio skill)
#
# TDD stub: ПАДАЕТ пока Dev не добавит skills-секцию с drawio в plugin.json.
# Note: текущий plugin.json НЕ имеет поля skills — description mentioning drawio is NOT sufficient.
#       The spec AC-002 explicitly requires a 'skills' section.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"

assert_file_exists "$PLUGIN_JSON" \
  "AC-014: plugins/gramax/.claude-plugin/plugin.json must exist"

if [ -f "$PLUGIN_JSON" ]; then
  if ! python3 -c "import json, sys; json.load(open('$PLUGIN_JSON'))" 2>/dev/null; then
    echo "  FAIL: AC-014: plugin.json is not valid JSON" >&2
    FAIL=$((FAIL + 1))
  else
    RESULT=$(python3 -c "
import json, sys
with open('$PLUGIN_JSON') as f:
    d = json.load(f)

# Spec AC-002: drawio must be declared in a 'skills' section (array or dict)
skills_field = d.get('skills', None)
if skills_field is None:
    print('NO_SKILLS_FIELD')
elif isinstance(skills_field, list):
    names = [s.get('name', s) if isinstance(s, dict) else s for s in skills_field]
    if 'drawio' in names:
        print('SKILLS_ARRAY_OK')
    else:
        print('SKILLS_ARRAY_MISSING_DRAWIO:' + str(names))
elif isinstance(skills_field, dict):
    if 'drawio' in skills_field:
        print('SKILLS_DICT_OK')
    else:
        print('SKILLS_DICT_MISSING_DRAWIO:' + str(list(skills_field.keys())))
else:
    print('SKILLS_FIELD_UNEXPECTED_TYPE:' + type(skills_field).__name__)
")
    case "$RESULT" in
      SKILLS_ARRAY_OK|SKILLS_DICT_OK)
        : # pass
        ;;
      NO_SKILLS_FIELD)
        echo "  FAIL: AC-014: plugin.json has no 'skills' field at all" >&2
        echo "         Dev must add: \"skills\": [{\"name\": \"drawio\", ...}, ...] (spec AC-002/FR-001)" >&2
        FAIL=$((FAIL + 1))
        ;;
      SKILLS_ARRAY_MISSING_DRAWIO:*|SKILLS_DICT_MISSING_DRAWIO:*)
        echo "  FAIL: AC-014: plugin.json skills list does not include 'drawio': $RESULT" >&2
        FAIL=$((FAIL + 1))
        ;;
      *)
        echo "  FAIL: AC-014: unexpected result from plugin.json skills check: $RESULT" >&2
        FAIL=$((FAIL + 1))
        ;;
    esac
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-014: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-014: plugin.json skills section declares drawio skill"
