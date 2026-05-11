#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-017-marketplace-description-updated.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# ADR: docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md (пункт 6 списка изменений)
# AC coverage:
#   Sunset pattern: metadata.description в marketplace.json НЕ упоминает claude-mermaid
#                   (должно быть заменено на актуальное описание с drawio skill)
#
# TDD stub: ПАДАЕТ пока Dev/Tech-writer не обновит marketplace.json description.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"

assert_file_exists "$MARKETPLACE" \
  "AC-017: .claude-plugin/marketplace.json must exist"

if [ -f "$MARKETPLACE" ]; then
  if ! python3 -c "import json; json.load(open('$MARKETPLACE'))" 2>/dev/null; then
    echo "  FAIL: AC-017: marketplace.json is not valid JSON" >&2
    FAIL=$((FAIL + 1))
  else
    # metadata.description must not mention claude-mermaid
    META_DESC=$(python3 -c "import json; d=json.load(open('$MARKETPLACE')); print(d.get('metadata',{}).get('description',''))")
    if echo "$META_DESC" | grep -qi 'claude-mermaid'; then
      echo "  FAIL: AC-017: marketplace.json metadata.description still mentions 'claude-mermaid'" >&2
      echo "         Current: $META_DESC" >&2
      echo "         Dev must update to reflect gramax:drawio skill instead" >&2
      FAIL=$((FAIL + 1))
    fi

    # gramax plugin description in plugins[] must not mention claude-mermaid
    GRAMAX_DESC=$(python3 -c "
import json
d = json.load(open('$MARKETPLACE'))
for p in d.get('plugins', []):
    if p.get('name') == 'gramax':
        print(p.get('description', ''))
        break
")
    if echo "$GRAMAX_DESC" | grep -qi 'claude-mermaid'; then
      echo "  FAIL: AC-017: marketplace.json plugins[gramax].description mentions 'claude-mermaid'" >&2
      echo "         Current: $GRAMAX_DESC" >&2
      FAIL=$((FAIL + 1))
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-017: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-017: marketplace.json description fields do not mention claude-mermaid"
