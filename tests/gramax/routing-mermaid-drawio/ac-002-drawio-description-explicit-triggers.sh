#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-002-drawio-description-explicit-triggers.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-003/FR-002 → description упоминает «drawio» (explicit trigger), НЕ упоминает «mermaid»
#                   в строке description (anti-trigger: не должен срабатывать на mermaid-запросы)
#
# TDD stub: ПАДАЕТ пока Dev не создаст SKILL.md с правильными description-формулировками.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL="$ROOT/plugins/gramax/skills/drawio/SKILL.md"

assert_file_exists "$SKILL" \
  "AC-002: plugins/gramax/skills/drawio/SKILL.md must exist before checking description"

if [ -f "$SKILL" ]; then
  # Extract description line from frontmatter only
  DESCRIPTION=$(sed -n '1,/^---$/p' "$SKILL" | tail -n +2 | grep '^description:' | head -1)

  if [ -z "$DESCRIPTION" ]; then
    echo "  FAIL: AC-002: no description field found in frontmatter" >&2
    FAIL=$((FAIL + 1))
  else
    # description must mention drawio (positive trigger)
    if ! echo "$DESCRIPTION" | grep -qi 'drawio'; then
      echo "  FAIL: AC-002: description must mention 'drawio' as explicit trigger, got: $DESCRIPTION" >&2
      FAIL=$((FAIL + 1))
    fi

    # description must NOT use mermaid as a trigger keyword (anti-trigger check)
    # It may mention mermaid as an anti-trigger redirect ("НЕ для mermaid"), but
    # the description itself should not cause Claude to activate on mermaid-requests.
    # We check: the primary trigger keywords in description must centre on drawio, not mermaid alone.
    # Specifically: the first trigger keyword must be drawio-related, not mermaid.
    if echo "$DESCRIPTION" | grep -qi 'нарисуй mermaid\|mermaid-диаграмм\|mermaid DSL'; then
      echo "  FAIL: AC-002: description must NOT include mermaid as a positive trigger" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-002: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-002: drawio description mentions drawio (trigger) and not mermaid as positive trigger"
