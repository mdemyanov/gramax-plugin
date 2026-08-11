#!/usr/bin/env bash
# tests/gramax/catalog-validator/ac-008-help-doc-pointer.sh
# Требование: content/30-requirements/2026-08-11-validation-contract.md AC-002 (FR-036)
# ADR: content/00-project/adr/0012-catalog-validation-contract.md, Решение 4 (argparse
#      epilog с текстом-указателем на README/SKILL.md/репозиторий).
# Природа: живой контракт — КРАСНЫЙ на момент создания (epilog ещё не добавлен — DEV-001).
# validate_structure.py вызывается read-only через --help — не модифицируется здесь.

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

HELP_OUT=$(cd "$ROOT" && uv run plugins/gramax/scripts/validate_structure.py --help 2>&1)

if ! echo "$HELP_OUT" | grep -qiE 'README|SKILL\.md|github\.com'; then
  echo "  FAIL: AC-002 — вывод --help обязан содержать указатель на документацию (README/SKILL.md/github.com), FR-036" >&2
  echo "  --- вывод --help ---" >&2
  echo "$HELP_OUT" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-008: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-008: --help содержит указатель на документацию"
