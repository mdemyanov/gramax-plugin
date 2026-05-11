#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-009-claude-mermaid-dir-removed.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# ADR: docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md (Решение 2)
# AC coverage:
#   AC-010/FR-008 → plugins/claude-mermaid/ не существует физически (или пуст)
#
# TDD stub: ПАДАЕТ пока Dev не выполнит git submodule deinit + git rm.
# Note: submodule не инициализирован (статус '-'), поэтому каталог может быть пустым.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

CLAUDE_MERMAID_DIR="$ROOT/plugins/claude-mermaid"

if [ -d "$CLAUDE_MERMAID_DIR" ]; then
  # Directory exists — check if it's empty (acceptable if submodule not initialized)
  FILE_COUNT=$(find "$CLAUDE_MERMAID_DIR" -mindepth 1 | wc -l | tr -d ' ')
  if [ "$FILE_COUNT" -gt 0 ]; then
    echo "  FAIL: AC-009: plugins/claude-mermaid/ must be removed, but contains $FILE_COUNT file(s)" >&2
    find "$CLAUDE_MERMAID_DIR" -mindepth 1 | head -5 >&2
    FAIL=$((FAIL + 1))
  else
    echo "  FAIL: AC-009: plugins/claude-mermaid/ directory still exists (even if empty)" >&2
    echo "         Dev must run: git rm -rf plugins/claude-mermaid (ADR-0009 Решение 2)" >&2
    FAIL=$((FAIL + 1))
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-009: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-009: plugins/claude-mermaid/ is absent (submodule removed)"
