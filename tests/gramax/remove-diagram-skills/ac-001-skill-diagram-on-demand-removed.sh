#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-001-skill-diagram-on-demand-removed.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-001 → каталог plugins/gramax/skills/diagram-on-demand/ не существует
#
# TDD stub: должен ПАДАТЬ пока Dev не удалит каталог.
# После Dev: тест станет зелёным.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

TARGET="$ROOT/plugins/gramax/skills/diagram-on-demand"

assert_dir_not_exists "$TARGET" \
  "AC-001: skills/diagram-on-demand/ must be deleted"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-001: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-001: skills/diagram-on-demand/ absent"
