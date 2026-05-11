#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-013-changelog-2-0-0-section.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-013 → plugins/gramax/CHANGELOG.md содержит секцию ## 2.0.0
#             с подразделами Removed (или эквивалент) и ### Migration
#             и датой в заголовке секции
#
# TDD stub: должен ПАДАТЬ пока Dev не добавит секцию 2.0.0 в CHANGELOG.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

CHANGELOG="$ROOT/plugins/gramax/CHANGELOG.md"

assert_file_exists "$CHANGELOG" \
  "AC-013: plugins/gramax/CHANGELOG.md must exist"

# Major version section header
assert_grep_regex "$CHANGELOG" "^## 2\.0\.0" \
  "AC-013: CHANGELOG must contain '## 2.0.0' section"

# Section must include a date (e.g., ## 2.0.0 — 2026-05-11 or ## 2.0.0 (2026-05-11))
assert_grep_regex "$CHANGELOG" "## 2\.0\.0.*(202[0-9]|—)" \
  "AC-013: '## 2.0.0' section must include a date"

# Removed subsection
assert_grep_regex "$CHANGELOG" "### (Removed|Удалено)" \
  "AC-013: CHANGELOG 2.0.0 must have '### Removed' (or 'Удалено') subsection"

# Changed subsection
assert_grep_regex "$CHANGELOG" "### (Changed|Изменено)" \
  "AC-013: CHANGELOG 2.0.0 must have '### Changed' (or 'Изменено') subsection"

# Migration notes subsection
assert_grep_regex "$CHANGELOG" "### Migration" \
  "AC-013: CHANGELOG 2.0.0 must have '### Migration' subsection"

# Boundary: Migration notes must mention the external plugin install command
assert_grep "$CHANGELOG" "Agents365-ai/365-skills" \
  "AC-013: CHANGELOG Migration notes must reference Agents365-ai/365-skills"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-013: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-013: CHANGELOG.md has complete 2.0.0 section"
