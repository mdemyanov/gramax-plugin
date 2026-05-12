#!/usr/bin/env bash
# tests/gramax/mermaid-file-based/ac-012-manifest-version-4.sh
# Spec: docs/superpowers/specs/2026-05-12-mermaid-file-based-design.md
# ADR:  docs/adr/0010-mermaid-file-based-workflow.md (Решение 1 — major bump 4.0.0)
# AC coverage:
#   (дополнительный AC из ADR) → plugin.json и marketplace.json содержат версию 4.0.0
#
# TDD stub: ПАДАЕТ на текущем plugin.json (version: "3.0.0").
# После реализации: Dev бампит версию до 4.0.0 в обоих манифестах одним коммитом.
#
# Уровень: manifest-validation (jq парсит JSON, проверяет version)

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$ROOT/.claude-plugin/marketplace.json"

# --- Sanity: jq доступен ---
if ! command -v jq >/dev/null 2>&1; then
  echo "  SKIP: jq не установлен — установи: brew install jq" >&2
  exit 0
fi

# --- plugin.json: version = "4.0.0" ---
assert_file_exists "$PLUGIN_JSON" \
  "AC-012: plugins/gramax/.claude-plugin/plugin.json должен существовать"

if [ -f "$PLUGIN_JSON" ]; then
  PLUGIN_VERSION="$(jq -r '.version' "$PLUGIN_JSON" 2>/dev/null)"
  assert_eq "$PLUGIN_VERSION" "4.0.0" \
    "AC-012: plugin.json version должен быть 4.0.0 (сейчас: $PLUGIN_VERSION)"
fi

# --- marketplace.json: metadata.version = "4.0.0" ---
assert_file_exists "$MARKETPLACE_JSON" \
  "AC-012: .claude-plugin/marketplace.json должен существовать"

if [ -f "$MARKETPLACE_JSON" ]; then
  MARKETPLACE_VERSION="$(jq -r '.metadata.version // .version' "$MARKETPLACE_JSON" 2>/dev/null)"
  assert_eq "$MARKETPLACE_VERSION" "4.0.0" \
    "AC-012: marketplace.json metadata.version должен быть 4.0.0 (сейчас: $MARKETPLACE_VERSION)"
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-012-manifest-version-4: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-012-manifest-version-4: plugin.json и marketplace.json содержат версию 4.0.0"
