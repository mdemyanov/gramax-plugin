#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-010-gitmodules-clean.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# ADR: docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md (Решение 2, шаг 4)
# AC coverage:
#   AC-009/FR-008 → .gitmodules либо отсутствует, либо НЕ содержит запись claude-mermaid
#
# TDD stub: ПАДАЕТ пока Dev не выполнит git rm plugins/claude-mermaid (шаг удаляет запись из .gitmodules).

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

GITMODULES="$ROOT/.gitmodules"

if [ -f "$GITMODULES" ]; then
  # .gitmodules exists — must NOT contain claude-mermaid entry
  if grep -q 'claude-mermaid' "$GITMODULES"; then
    echo "  FAIL: AC-010: .gitmodules still contains 'claude-mermaid' submodule entry" >&2
    echo "         Dev must run: git rm -rf plugins/claude-mermaid" >&2
    grep -n 'claude-mermaid' "$GITMODULES" >&2
    FAIL=$((FAIL + 1))
  fi
else
  # .gitmodules absent — this is also acceptable (no submodules at all)
  : # pass
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-010: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-010: .gitmodules has no claude-mermaid entry (or file absent)"
