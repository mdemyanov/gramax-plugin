#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-009-readme-prerequisites-block.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# ADR: docs/adr/0008-drop-internal-drawio-skills.md Решения 4, 6
# AC coverage:
#   AC-009 → plugins/gramax/README.md содержит prerequisites-блок внешнего drawio-плагина:
#             draw.io desktop, /plugin marketplace add Agents365-ai/365-skills,
#             /plugin install drawio, Python 3 (для repair_png.py)
#
# TDD stub: должен ПАДАТЬ пока Dev не добавит prerequisites-блок в README.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

README="$ROOT/plugins/gramax/README.md"

assert_file_exists "$README" \
  "AC-009: plugins/gramax/README.md must exist"

assert_grep "$README" "draw.io desktop" \
  "AC-009: README must mention 'draw.io desktop'"

assert_grep "$README" "/plugin marketplace add Agents365-ai/365-skills" \
  "AC-009: README must include '/plugin marketplace add Agents365-ai/365-skills'"

assert_grep "$README" "/plugin install drawio" \
  "AC-009: README must include '/plugin install drawio'"

assert_grep_regex "$README" "Python 3|python3|repair_png" \
  "AC-009: README must mention Python 3 (required by repair_png.py)"

# ADR-0008 Решение 6: WARNING about mermaid-skill conflict
assert_grep_regex "$README" "(Warning|WARNING|Предупреждение)" \
  "AC-009: README must contain a warning about mermaid-skill conflict (Решение 6)"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-009: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-009: README contains drawio prerequisites block"
