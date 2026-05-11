#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-004-drawio-skill-workflow-section.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-005/FR-005 → body содержит секцию про двухшаговый workflow:
#                   drawio-skill создаёт .svg → writer-skill вставляет тег
#
# TDD stub: ПАДАЕТ пока Dev не добавит workflow-секцию.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL="$ROOT/plugins/gramax/skills/drawio/SKILL.md"

assert_file_exists "$SKILL" \
  "AC-004: plugins/gramax/skills/drawio/SKILL.md must exist"

if [ -f "$SKILL" ]; then
  # Must mention svg file creation (step 1 of workflow)
  if ! grep -qiE '\.svg|svg-файл' "$SKILL"; then
    echo "  FAIL: AC-004: SKILL.md must describe Step 1 — drawio-skill creates .svg file" >&2
    FAIL=$((FAIL + 1))
  fi

  # Must mention writer-skill as step 2
  if ! grep -qiE 'writer[-_]?skill|gramax.*writer|writer.*граксм|writer.*skill' "$SKILL"; then
    echo "  FAIL: AC-004: SKILL.md must describe Step 2 — writer-skill inserts the tag" >&2
    FAIL=$((FAIL + 1))
  fi

  # Must contain the concept of two steps (Шаг 1 / Шаг 2, or Step 1/Step 2, or numbered items)
  if ! grep -qiE 'Шаг [12]|Step [12]|шаг1|шаг2|двухшаговый|two.step|2-step' "$SKILL"; then
    echo "  FAIL: AC-004: SKILL.md must explicitly describe two-step workflow (Шаг 1/Шаг 2 or equivalent)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-004: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-004: drawio SKILL.md contains two-step workflow section (.svg creation + writer-skill)"
