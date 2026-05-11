#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-016-no-orphan-references.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# ADR: docs/adr/0008-drop-internal-drawio-skills.md (Контракт с QA-author: edge cases)
# AC coverage:
#   AC-016 → ни один оставшийся файл плагина не ссылается на удалённые скрипты:
#             drawio_convert, find_doc_root, save_diagram, insert_diagram_ref, validate_diagram_type
#             Охват: skills/, agents/, .claude-plugin/, README.md, CHANGELOG.md
#
# TDD stub: должен ПАДАТЬ пока в плагине остаются ссылки на удалённые скрипты.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

PLUGIN_DIR="$ROOT/plugins/gramax"

# Build a combined pattern for all deleted script names
PATTERN="drawio_convert|find_doc_root|save_diagram|insert_diagram_ref|validate_diagram_type"

# Search all relevant subdirectories (wide sweep per ADR-0008 edge cases)
SEARCH_PATHS=(
  "$PLUGIN_DIR/skills"
  "$PLUGIN_DIR/.claude-plugin"
  "$PLUGIN_DIR/README.md"
  "$PLUGIN_DIR/CHANGELOG.md"
)

# Add agents dir if it exists
if [ -d "$PLUGIN_DIR/agents" ]; then
  SEARCH_PATHS+=("$PLUGIN_DIR/agents")
fi

# Add scripts dir (residual references after deletion)
if [ -d "$PLUGIN_DIR/scripts" ]; then
  SEARCH_PATHS+=("$PLUGIN_DIR/scripts")
fi

TOTAL_MATCHES=0
for path in "${SEARCH_PATHS[@]}"; do
  if [ -e "$path" ]; then
    MATCHES="$( (grep -rn -E "$PATTERN" "$path" 2>/dev/null || true) | wc -l | tr -d ' ')"
    if [ "$MATCHES" -gt 0 ]; then
      echo "  FAIL: AC-016: found $MATCHES orphan reference(s) in $path:" >&2
      grep -rn -E "$PATTERN" "$path" 2>/dev/null | head -10 >&2
      TOTAL_MATCHES=$((TOTAL_MATCHES + MATCHES))
    fi
  fi
done

if [ "$TOTAL_MATCHES" -gt 0 ]; then
  echo "  FAIL: AC-016: total $TOTAL_MATCHES orphan reference(s) to deleted scripts remain" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-016: $FAIL assertion(s) failed ($TOTAL_MATCHES orphan refs)"
  exit 1
fi
pass_msg "ac-016: no orphan references to deleted scripts anywhere in plugin"
