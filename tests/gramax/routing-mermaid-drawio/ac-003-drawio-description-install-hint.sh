#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-003-drawio-description-install-hint.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-004/FR-004 → description или body skill'а упоминает «Agents365-ai/drawio-skill» или
#                   «Agents365-ai/365-skills» как инструкцию по установке внешнего плагина
#
# TDD stub: ПАДАЕТ пока Dev не добавит install-hint в SKILL.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL="$ROOT/plugins/gramax/skills/drawio/SKILL.md"

assert_file_exists "$SKILL" \
  "AC-003: plugins/gramax/skills/drawio/SKILL.md must exist"

if [ -f "$SKILL" ]; then
  # description OR body must mention the external plugin marketplace reference
  if ! grep -qiE 'Agents365-ai/(drawio-skill|365-skills)' "$SKILL"; then
    echo "  FAIL: AC-003: SKILL.md must mention 'Agents365-ai/drawio-skill' or 'Agents365-ai/365-skills'" >&2
    echo "         as installation hint for the external plugin (FR-004)" >&2
    FAIL=$((FAIL + 1))
  fi

  # Also verify plugin install command is present
  if ! grep -qE '/plugin install drawio|plugin marketplace add' "$SKILL"; then
    echo "  FAIL: AC-003: SKILL.md must include install command ('/plugin install drawio' or 'plugin marketplace add')" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-003: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-003: drawio SKILL.md contains Agents365-ai install hint and install command"
