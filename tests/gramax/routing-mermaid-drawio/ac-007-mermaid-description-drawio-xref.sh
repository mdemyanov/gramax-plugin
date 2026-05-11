#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-007-mermaid-description-drawio-xref.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-008/FR-007 → description в mermaid/SKILL.md упоминает «gramax:drawio» как cross-ref,
#                   НЕ упоминает «Agents365-ai» как конфликтующий инструмент
#
# TDD stub: ПАДАЕТ пока Dev не обновит mermaid description.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

assert_file_exists "$SKILL" \
  "AC-007: plugins/gramax/skills/mermaid/SKILL.md must exist"

if [ -f "$SKILL" ]; then
  # Extract description line from frontmatter
  DESCRIPTION=$(sed -n '1,/^---$/p' "$SKILL" | tail -n +2 | grep '^description:' | head -1)

  if [ -z "$DESCRIPTION" ]; then
    echo "  FAIL: AC-007: no description field found in mermaid/SKILL.md frontmatter" >&2
    FAIL=$((FAIL + 1))
  else
    # description must contain cross-ref to gramax:drawio
    if ! echo "$DESCRIPTION" | grep -qE 'gramax:drawio|граксм:drawio'; then
      echo "  FAIL: AC-007: mermaid description must contain 'gramax:drawio' cross-reference" >&2
      echo "         Current description: $DESCRIPTION" >&2
      FAIL=$((FAIL + 1))
    fi

    # description must NOT mention Agents365-ai as a conflicting tool warning
    # (old pattern: "Для drawio используй внешний плагин drawio из marketplace Agents365-ai/365-skills")
    if echo "$DESCRIPTION" | grep -qE 'Agents365-ai'; then
      echo "  FAIL: AC-007: mermaid description must NOT reference 'Agents365-ai'" >&2
      echo "         (routing is now done via gramax:drawio, not direct marketplace reference)" >&2
      echo "         Current description: $DESCRIPTION" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-007: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-007: mermaid description has gramax:drawio cross-ref and no Agents365-ai reference"
