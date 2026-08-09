#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-002-drawio-tag-format.sh
# Требование: FR-007. Происхождение: archive/remove-diagram-skills ac-008 (часть про тег),
#             archive/routing-mermaid-drawio ac-005 — переформулированы под канон v4.1.0.
# Природа: живой контракт. КРАСНЫЙ до FR-017/FR-018 — недомигрированный тег есть дефект v4.1.0.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
CANON='<drawio path="[^"]*" width="[^"]*" height="[^"]*"/>'

# Позитив: канонический тег задокументирован там, где writer его ищет
assert_grep_regex "$ROOT/plugins/gramax/skills/writer/references/drawio.md" "$CANON" \
  "FR-007: writer/references/drawio.md обязан показывать канонический тег"

# Негатив: ни один живой документ плагина не учит устаревшему синтаксису.
# Исключены: CHANGELOG (история релизов) и blocks.md (явная пометка «устаревший формат»).
STALE=$(grep -rnE '\[drawio:|<Image src' "$ROOT/plugins/gramax" --include='*.md' 2>/dev/null \
        | grep -v '/CHANGELOG\.md:' \
        | grep -v '/references/blocks\.md:' || true)

if [ -n "$STALE" ]; then
  echo "  FAIL: FR-007: живые документы плагина всё ещё учат устаревшему синтаксису тега:" >&2
  echo "$STALE" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-002: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-002: формат drawio-тега канонический во всех живых документах"
