#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-006-drawio-skill-fallback-section.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-006/FR-006 → body содержит cross-reference на gramax:mermaid для mermaid-запросов
#                   (fallback / «не для» секция; также покрывает ambiguous-request алгоритм ADR-0009)
#
# TDD stub: ПАДАЕТ пока Dev не добавит fallback/cross-ref секцию в drawio/SKILL.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL="$ROOT/plugins/gramax/skills/drawio/SKILL.md"

assert_file_exists "$SKILL" \
  "AC-006: plugins/gramax/skills/drawio/SKILL.md must exist"

if [ -f "$SKILL" ]; then
  # Must contain cross-reference to gramax:mermaid
  if ! grep -qE 'gramax:mermaid|граксм:mermaid' "$SKILL"; then
    echo "  FAIL: AC-006: SKILL.md must reference 'gramax:mermaid' for redirecting mermaid requests" >&2
    FAIL=$((FAIL + 1))
  fi

  # Must mention mermaid as the alternative (either «Не для» section or fallback)
  if ! grep -qi 'mermaid' "$SKILL"; then
    echo "  FAIL: AC-006: SKILL.md must mention 'mermaid' (as alternative/cross-ref) at least once" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-006: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-006: drawio SKILL.md has fallback/cross-ref section pointing to gramax:mermaid"
