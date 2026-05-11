#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-008-writer-drawio-ref-new-workflow.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# ADR: docs/adr/0008-drop-internal-drawio-skills.md Решение 4
# AC coverage:
#   AC-008 → writer/references/drawio.md содержит обязательные секции нового workflow
#            (Prerequisites, draw.io desktop, Python 3, Agents365-ai install commands,
#             двухшаговый workflow, Gramax-тег формат)
#
# TDD stub: должен ПАДАТЬ пока Dev не реструктурирует drawio.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

DRAWIO_REF="$ROOT/plugins/gramax/skills/writer/references/drawio.md"

assert_file_exists "$DRAWIO_REF" \
  "AC-008: writer/references/drawio.md must exist"

# Prerequisites section
assert_grep "$DRAWIO_REF" "Prerequisites" \
  "AC-008: drawio.md must contain 'Prerequisites' section"

# draw.io desktop mentioned
assert_grep "$DRAWIO_REF" "draw.io desktop" \
  "AC-008: drawio.md must mention 'draw.io desktop'"

# Python 3 mentioned (required by repair_png.py in drawio-skill)
assert_grep_regex "$DRAWIO_REF" "Python 3|python3" \
  "AC-008: drawio.md must mention Python 3"

# External plugin install commands (ADR-0008 Решение 4)
assert_grep "$DRAWIO_REF" "/plugin marketplace add Agents365-ai/365-skills" \
  "AC-008: drawio.md must include '/plugin marketplace add Agents365-ai/365-skills'"

assert_grep "$DRAWIO_REF" "/plugin install drawio" \
  "AC-008: drawio.md must include '/plugin install drawio'"

# Two-step workflow described
assert_grep_regex "$DRAWIO_REF" "(двухшаговый|Двухшаговый|Шаг 1|Step 1)" \
  "AC-008: drawio.md must describe the two-step workflow (Шаг 1 or двухшаговый)"

# Gramax tag format preserved — NFR-005: syntax must remain
assert_grep_regex "$DRAWIO_REF" '\[drawio:|<Image' \
  "AC-008: drawio.md must contain Gramax tag format ([drawio: or <Image)"

# Important note: drawio-skill does not know .doc-root.yaml
assert_grep_regex "$DRAWIO_REF" "doc-root|не вставляет|не знает" \
  "AC-008: drawio.md must note that drawio-skill doesn't auto-insert tag"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-008: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-008: writer/references/drawio.md contains new workflow structure"
