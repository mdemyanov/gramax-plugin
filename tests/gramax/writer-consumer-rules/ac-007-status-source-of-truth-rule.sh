#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-007-status-source-of-truth-rule.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-007 (FR-070).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел C —
#   тело статьи — источник истины, frontmatter — проекция, обновляется тем же изменением;
#   расхождение носителей — дефект.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-004 не начат).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
WRITER_DIR="$ROOT/plugins/gramax/skills/writer"

if ! grep -rliE 'источник истины|source of truth' "$WRITER_DIR" 2>/dev/null | grep -q .; then
  echo "  FAIL: AC-007 — ни один файл skills/writer/ не формулирует правило синхронизации статуса ('источник истины'/'source of truth', FR-070)" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: правило синхронизации статусов (источник истины) задокументировано"
