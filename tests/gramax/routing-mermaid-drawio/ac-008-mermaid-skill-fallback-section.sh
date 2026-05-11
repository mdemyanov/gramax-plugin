#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-008-mermaid-skill-fallback-section.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# ADR: docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md (Решение 1, Решение 6)
# AC coverage:
#   AC-008/FR-006 → body mermaid/SKILL.md содержит секцию про уточняющий вопрос
#                   при ambiguous-request (вариант B из ADR-0009: mermaid — владелец generic-триггеров)
#
# TDD stub: ПАДАЕТ пока Dev не добавит fallback-секцию в mermaid/SKILL.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

assert_file_exists "$SKILL" \
  "AC-008: plugins/gramax/skills/mermaid/SKILL.md must exist"

if [ -f "$SKILL" ]; then
  # Must contain clarifying question algorithm (keyword: уточняющий / уточни / движок / engine)
  if ! grep -qiE 'уточн|ambiguous|движок|engine|какой движок|какой инструмент' "$SKILL"; then
    echo "  FAIL: AC-008: mermaid/SKILL.md must contain ambiguous-request fallback section" >&2
    echo "         (should ask clarifying question: mermaid vs drawio — ADR-0009 Решение 6)" >&2
    FAIL=$((FAIL + 1))
  fi

  # The fallback section must reference drawio as the alternative
  if ! grep -qiE 'drawio.*движок|движок.*drawio|drawio.*альтернатив|drawio.*вместо|drawio.*вариант|drawio.*option' "$SKILL"; then
    # More lenient: at minimum drawio should appear in context of the fallback question
    DRAWIO_COUNT=$(grep -c -i 'drawio' "$SKILL" 2>/dev/null || echo 0)
    if [ "$DRAWIO_COUNT" -eq 0 ]; then
      echo "  FAIL: AC-008: mermaid/SKILL.md fallback section must mention drawio as an option" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-008: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-008: mermaid/SKILL.md has ambiguous-request fallback section with drawio alternative"
