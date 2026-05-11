#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-005-drawio-skill-gramax-tags.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-005/FR-005 → body упоминает оба Gramax-формата вставки:
#                   [drawio:...] (Markdown) и <Image src (XML)
#
# TDD stub: ПАДАЕТ пока Dev не задокументирует оба тега в SKILL.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL="$ROOT/plugins/gramax/skills/drawio/SKILL.md"

assert_file_exists "$SKILL" \
  "AC-005: plugins/gramax/skills/drawio/SKILL.md must exist"

if [ -f "$SKILL" ]; then
  # Must mention Markdown tag format: [drawio:
  if ! grep -qF '[drawio:' "$SKILL"; then
    echo "  FAIL: AC-005: SKILL.md must mention Markdown tag format '[drawio:...]'" >&2
    FAIL=$((FAIL + 1))
  fi

  # Must mention XML tag format: <Image src
  if ! grep -qE '<Image src|<image src' "$SKILL"; then
    echo "  FAIL: AC-005: SKILL.md must mention XML tag format '<Image src=\"...\" />'" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-005: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-005: drawio SKILL.md documents both Gramax tag formats: [drawio:...] and <Image src"
