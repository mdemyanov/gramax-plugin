#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-002-skill-diagrams-removed.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-002 → каталог plugins/gramax/skills/diagrams/ не существует
#
# TDD stub: должен ПАДАТЬ пока Dev не удалит каталог.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

TARGET="$ROOT/plugins/gramax/skills/diagrams"

assert_dir_not_exists "$TARGET" \
  "AC-002: skills/diagrams/ must be deleted"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-002: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-002: skills/diagrams/ absent"
