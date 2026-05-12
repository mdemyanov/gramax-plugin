#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-004-tag-has-width-height.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md
# AC coverage:
#   AC-004 → тег в md содержит атрибуты width и height
#
# TDD stub: ПАДАЕТ пока Dev не реализует вставку тега с атрибутами.
# После реализации: тег содержит оба атрибута.
#
# Уровень: smoke (grep на атрибуты)
# Граничные кейсы:
#   - оба атрибута из default (800px / 450px)
#   - пользователь задал только width → height дефолтный

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# --- Setup ---
mkdir -p "$TMPDIR_TEST/docs/auth"
TARGET_PAGE="$TMPDIR_TEST/docs/auth/overview.md"
cp "$SCRIPT_DIR/fixtures/clean-article.md" "$TARGET_PAGE"

# --- AC-004: оба атрибута width и height должны присутствовать в теге ---
echo "TODO: AC-004 — тег <mermaid .../> должен содержать атрибуты width= и height=" >&2
echo "  Ожидается: grep -q 'width=\"' $TARGET_PAGE && grep -q 'height=\"' $TARGET_PAGE" >&2

assert_grep "$TARGET_PAGE" 'width="' \
  "AC-004: тег в md должен содержать атрибут width"

assert_grep "$TARGET_PAGE" 'height="' \
  "AC-004: тег в md должен содержать атрибут height"

# --- Boundary: fixture expected-tag.md используется как reference ---
# Этот assert ПРОХОДИТ уже сейчас (fixture корректная)
FIXTURE="$SCRIPT_DIR/fixtures/expected-tag.md"
assert_file_exists "$FIXTURE" \
  "AC-004 fixture: expected-tag.md должен существовать"

if [ -f "$FIXTURE" ]; then
  assert_grep "$FIXTURE" 'width="' \
    "AC-004 fixture: expected-tag.md содержит атрибут width"
  assert_grep "$FIXTURE" 'height="' \
    "AC-004 fixture: expected-tag.md содержит атрибут height"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-004-tag-has-width-height: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-004-tag-has-width-height: тег содержит атрибуты width и height"
