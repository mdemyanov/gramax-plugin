#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-003-md-contains-tag.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md
# AC coverage:
#   AC-003 → target_page содержит тег <mermaid path="./..."/> после вставки
#
# TDD stub: ПАДАЕТ пока Dev не реализует вставку тега в md.
# После реализации: Edit tool вставляет тег-ссылку в md-файл.
#
# Уровень: smoke (grep на наличие тега в md-файле)

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

# --- AC-003: тег <mermaid path="./..."/> должен появиться в md после вызова skill ---
echo "TODO: AC-003 — skill должен вставить тег <mermaid path=\"./overview-auth-flow.mermaid\" .../> в $TARGET_PAGE" >&2
echo "  Ожидается: grep -q '<mermaid path=\"./' $TARGET_PAGE" >&2

# Файл существует, но тег ещё не вставлен — тест ПАДАЕТ на assert_grep
assert_grep "$TARGET_PAGE" '<mermaid path="./' \
  "AC-003: md-файл должен содержать тег <mermaid path=\"./\"> после вызова skill"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-003-md-contains-tag: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-003-md-contains-tag: target_page содержит <mermaid path=\"./\"> тег"
