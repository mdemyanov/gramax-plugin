#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-001-project-plugin-removed.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-1
# AC coverage:
#   AC-1  → локальный плагин project удалён, settings.json без упоминаний
#   AC-11 → tests/project/ удалён

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0

assert_dir_not_exists ".claude/plugins/project" \
  "AC-1: каталог локального плагина должен быть удалён"
assert_file_not_exists ".claude/.claude-plugin/marketplace.json" \
  "AC-1: внутренний marketplace-манифест должен быть удалён"
assert_dir_not_exists "tests/project" \
  "AC-11: tests/project должен быть удалён вместе с плагином"

assert_file_exists ".claude/settings.json" \
  "FR-1: settings.json должен существовать всегда"

if [ -f ".claude/settings.json" ]; then
  assert_no_grep ".claude/settings.json" "gramax-plugin-internal-local" \
    "AC-1: settings.json не должен упоминать внутренний marketplace"
  assert_no_grep ".claude/settings.json" "project@" \
    "AC-1: settings.json не должен включать плагин project"
  if ! python3 -m json.tool ".claude/settings.json" > /dev/null 2>&1; then
    echo "  FAIL: AC-1: .claude/settings.json — невалидный JSON" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-001: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-001: локальный плагин project удалён, settings.json чист"
