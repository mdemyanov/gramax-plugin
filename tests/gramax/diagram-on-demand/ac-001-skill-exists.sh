#!/usr/bin/env bash
# AC-001: SKILL.md создан для diagram-on-demand, frontmatter валидный
# Spec: docs/superpowers/specs/2026-05-08-diagram-on-demand-design.md
# ADR: docs/adr/0001-diagram-on-demand-plugin-split.md (один skill в plugins/gramax/skills/)
# Status: FAILING (TDD stub — Dev должен сделать зелёным)
#
# Coverage:
#   AC-001 → проверяет существование SKILL.md и обязательные поля frontmatter

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SKILL_FILE="$ROOT/plugins/gramax/skills/diagram-on-demand/SKILL.md"

assert_file_exists "$SKILL_FILE" "SKILL.md must exist at skills/diagram-on-demand/SKILL.md"
assert_grep "$SKILL_FILE" "diagram-on-demand" "SKILL.md must mention skill name"
assert_grep_regex "$SKILL_FILE" "^title:" "SKILL.md must have title frontmatter field"
assert_grep_regex "$SKILL_FILE" "^(trigger|triggers):" "SKILL.md must have trigger(s) frontmatter field"
assert_grep "$SKILL_FILE" "mermaid" "SKILL.md must reference mermaid engine"
assert_grep "$SKILL_FILE" "drawio" "SKILL.md must reference drawio engine"

if [ "$FAIL" -gt 0 ]; then
  echo "FAIL: ac-001-skill-exists — $FAIL assertion(s) failed" >&2
  exit 1
fi
echo "OK: ac-001-skill-exists"
