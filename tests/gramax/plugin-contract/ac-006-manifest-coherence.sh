#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-006-manifest-coherence.sh
# Требование: FR-011. Происхождение: поглощает шесть версионных пинов трёх архивных suite
#             (remove ac-011/012, routing ac-012/013, mermaid ac-012). Проверяет не число,
#             а инвариант ADR-0006 — синхронность двух манифестов, которая истинна всегда.
# Природа: regression guard — зелёный на момент создания.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"
MARKET_JSON="$ROOT/.claude-plugin/marketplace.json"
CHANGELOG="$ROOT/plugins/gramax/CHANGELOG.md"

assert_file_exists "$PLUGIN_JSON" "FR-011: plugin.json должен существовать"
assert_file_exists "$MARKET_JSON" "FR-011: marketplace.json должен существовать"

PV=$(python3 -c "import json;print(json.load(open('$PLUGIN_JSON')).get('version','MISSING'))" 2>/dev/null || echo PARSE_ERROR)
MV=$(python3 -c "import json;print(json.load(open('$MARKET_JSON')).get('metadata',{}).get('version','MISSING'))" 2>/dev/null || echo PARSE_ERROR)

assert_eq "$PV" "$MV" \
  "FR-011: версии plugin.json и marketplace.json обязаны совпадать (ADR-0006, синхронное версионирование)"

if [ "$PV" != "MISSING" ] && [ "$PV" != "PARSE_ERROR" ]; then
  assert_grep "$CHANGELOG" "## $PV" \
    "FR-011: CHANGELOG обязан иметь секцию для текущей версии ($PV)"
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-006: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-006: манифесты согласованы, CHANGELOG несёт секцию текущей версии"
