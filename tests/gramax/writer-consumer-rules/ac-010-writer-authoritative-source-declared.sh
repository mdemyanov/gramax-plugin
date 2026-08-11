#!/usr/bin/env bash
# tests/gramax/writer-consumer-rules/ac-010-writer-authoritative-source-declared.sh
# Требование: content/30-requirements/2026-08-11-writer-consumer-rules.md, AC-010 (FR-074).
# Диспозиция: content/40-architecture/2026-08-11-writer-rules-disposition.md, раздел F —
#   2–3 строки в SKILL.md → "Core Principles": writer — единственный authoritative источник
#   Gramax-соглашений.
# Природа: живой контракт — КРАСНЫЙ на момент создания (DEV-004 не начат).

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
SKILL_MD="$ROOT/plugins/gramax/skills/writer/SKILL.md"

assert_grep_regex_i "$SKILL_MD" 'authoritative|единственн.{0,20}источник' \
  "AC-010 — SKILL.md должен явно объявить writer единственным authoritative источником Gramax-соглашений (FR-074)"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-010: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-010: writer объявляет себя authoritative-источником Gramax-соглашений"
