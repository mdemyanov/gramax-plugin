#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-003-orphan-scripts-removed.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# AC coverage:
#   AC-003 → четыре скрипта-сироты отсутствуют в plugins/gramax/scripts/
#            find_doc_root.sh, save_diagram.sh, insert_diagram_ref.sh, validate_diagram_type.sh
#
# TDD stub: должен ПАДАТЬ пока Dev не удалит скрипты.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

SCRIPTS_DIR="$ROOT/plugins/gramax/scripts"

assert_file_not_exists "$SCRIPTS_DIR/find_doc_root.sh" \
  "AC-003: find_doc_root.sh must be deleted"

assert_file_not_exists "$SCRIPTS_DIR/save_diagram.sh" \
  "AC-003: save_diagram.sh must be deleted"

assert_file_not_exists "$SCRIPTS_DIR/insert_diagram_ref.sh" \
  "AC-003: insert_diagram_ref.sh must be deleted"

assert_file_not_exists "$SCRIPTS_DIR/validate_diagram_type.sh" \
  "AC-003: validate_diagram_type.sh must be deleted"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-003: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-003: all 4 orphan scripts absent"
