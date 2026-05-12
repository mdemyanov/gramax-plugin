#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-006-tag-self-closing.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md
# AC coverage:
#   AC-006 → тег в md является самозакрывающимся (без содержимого между тегами)
#             Форма: <mermaid path="..." width="..." height="..."/>
#
# TDD stub: ПАДАЕТ пока Dev не реализует вставку самозакрывающегося тега.
#
# Уровень: smoke (grep с regex на самозакрывающийся тег)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# Regex: самозакрывающийся тег с тремя обязательными атрибутами
SELF_CLOSING_REGEX='<mermaid path="[^"]*" width="[^"]*" height="[^"]*"/>'

# --- Setup ---
mkdir -p "$TMPDIR_TEST/docs/auth"
TARGET_PAGE="$TMPDIR_TEST/docs/auth/overview.md"
cp "$SCRIPT_DIR/fixtures/clean-article.md" "$TARGET_PAGE"

# --- AC-006: тег самозакрывающийся ---
echo "TODO: AC-006 — тег должен быть самозакрывающимся: <mermaid path=\"...\" width=\"...\" height=\"...\"/>" >&2
echo "  Ожидается: grep -qE '$SELF_CLOSING_REGEX' $TARGET_PAGE" >&2

assert_grep_regex "$TARGET_PAGE" "$SELF_CLOSING_REGEX" \
  "AC-006: тег в md должен быть самозакрывающимся с path, width, height атрибутами"

# --- Reference fixture: expected-tag.md демонстрирует корректный формат ---
FIXTURE="$SCRIPT_DIR/fixtures/expected-tag.md"
if [ -f "$FIXTURE" ]; then
  assert_grep_regex "$FIXTURE" "$SELF_CLOSING_REGEX" \
    "AC-006 fixture: expected-tag.md содержит самозакрывающийся тег"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-006-tag-self-closing: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-006-tag-self-closing: тег самозакрывающийся <mermaid path=... width=... height=.../>"
