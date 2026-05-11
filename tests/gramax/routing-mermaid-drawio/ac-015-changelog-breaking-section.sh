#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-015-changelog-breaking-section.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# AC coverage:
#   AC-013/FR-011 → plugins/gramax/CHANGELOG.md содержит секцию ## 3.0.0
#                   с подсекциями ### Removed, ### Added, ### Changed, ### Migration
#
# TDD stub: ПАДАЕТ пока Tech-writer не создаст секцию 3.0.0 в CHANGELOG.md.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

CHANGELOG="$ROOT/plugins/gramax/CHANGELOG.md"

assert_file_exists "$CHANGELOG" \
  "AC-015: plugins/gramax/CHANGELOG.md must exist"

if [ -f "$CHANGELOG" ]; then
  # Must have ## 3.0.0 heading
  assert_grep_regex "$CHANGELOG" '^## 3\.0\.0' \
    "AC-015: CHANGELOG.md must contain '## 3.0.0' section"

  # Must have ### Removed subsection
  assert_grep_regex "$CHANGELOG" '^### Removed' \
    "AC-015: CHANGELOG.md ## 3.0.0 must have '### Removed' subsection"

  # Must have ### Added subsection
  assert_grep_regex "$CHANGELOG" '^### Added' \
    "AC-015: CHANGELOG.md ## 3.0.0 must have '### Added' subsection"

  # Must have ### Changed subsection
  assert_grep_regex "$CHANGELOG" '^### Changed' \
    "AC-015: CHANGELOG.md ## 3.0.0 must have '### Changed' subsection"

  # Must have ### Migration subsection (breaking change migration notes)
  assert_grep_regex "$CHANGELOG" '^### Migration' \
    "AC-015: CHANGELOG.md ## 3.0.0 must have '### Migration' subsection (breaking change)"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-015: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-015: CHANGELOG.md has ## 3.0.0 with Removed/Added/Changed/Migration subsections"
