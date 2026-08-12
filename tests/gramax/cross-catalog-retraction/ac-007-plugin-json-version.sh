#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/ac-007-plugin-json-version.sh
# Требование: content/30-requirements/2026-08-13-cross-catalog-retraction.md, AC-007 (FR-102).
# Точечная проверка через jq (реальный парсинг JSON), не grep по сырому файлу — так прямо
# предписано и требованием, и ADR-0017 (Решение 3, «Bump выполняет Tech-writer... после Dev +
# QA-runner»).
#
# Природа: живой контракт — КРАСНЫЙ на момент создания (plugin.json несёт "4.2.0").

set -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
PLUGIN_JSON="$ROOT/plugins/gramax/.claude-plugin/plugin.json"

assert_file_exists "$PLUGIN_JSON" "AC-007: plugin.json должен существовать"

if [ -f "$PLUGIN_JSON" ]; then
  if ! command -v jq > /dev/null 2>&1; then
    echo "  FAIL: AC-007 — jq не установлен: точечная проверка версии по контракту AC-007 невозможна (grep-фолбэк намеренно не используется — AC-007 явно требует jq, не grep)" >&2
    FAIL=$((FAIL + 1))
  else
    VERSION="$(jq -r '.version' "$PLUGIN_JSON" 2>/dev/null)"
    if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
      echo "  FAIL: AC-007 — 'jq -r .version' вернул пусто/null — plugin.json невалиден или без поля 'version'" >&2
      FAIL=$((FAIL + 1))
    else
      assert_eq "$VERSION" "4.2.1" "AC-007 — 'jq -r .version' plugin.json должен вернуть ровно '4.2.1' (FR-102)"
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: plugin.json version == 4.2.1"
