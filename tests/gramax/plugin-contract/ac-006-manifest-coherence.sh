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

# MISSING/PARSE_ERROR обязаны быть самостоятельными причинами падения — иначе одинаковая порча
# обоих манифестов (например, find-replace, снёсший ключ 'version' в обоих JSON разом) даёт
# PV=MV и assert_eq ложно проходит, хотя инвариант ADR-0006 не проверен вовсе.
PV_READABLE=1
if [ "$PV" = "MISSING" ]; then
  echo "  FAIL: FR-011: plugin.json не содержит поле 'version'" >&2
  FAIL=$((FAIL + 1))
  PV_READABLE=0
elif [ "$PV" = "PARSE_ERROR" ]; then
  echo "  FAIL: FR-011: plugin.json — невалидный JSON, версия не читается" >&2
  FAIL=$((FAIL + 1))
  PV_READABLE=0
fi

MV_READABLE=1
if [ "$MV" = "MISSING" ]; then
  echo "  FAIL: FR-011: marketplace.json не содержит поле 'metadata.version'" >&2
  FAIL=$((FAIL + 1))
  MV_READABLE=0
elif [ "$MV" = "PARSE_ERROR" ]; then
  echo "  FAIL: FR-011: marketplace.json — невалидный JSON, версия не читается" >&2
  FAIL=$((FAIL + 1))
  MV_READABLE=0
fi

# Сравнение — сам инвариант ADR-0006 — имеет смысл только когда обе версии реально прочитаны.
# Иначе "версии разошлись" маскирует более базовый отказ "версия не читается".
if [ "$PV_READABLE" -eq 1 ] && [ "$MV_READABLE" -eq 1 ]; then
  assert_eq "$PV" "$MV" \
    "FR-011: версии plugin.json и marketplace.json обязаны совпадать (ADR-0006, синхронное версионирование)"
fi

if [ "$PV_READABLE" -eq 1 ]; then
  assert_grep "$CHANGELOG" "## $PV" \
    "FR-011: CHANGELOG обязан иметь секцию для текущей версии ($PV)"
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-006: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-006: манифесты согласованы, CHANGELOG несёт секцию текущей версии"
