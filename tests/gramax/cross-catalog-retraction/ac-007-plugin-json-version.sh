#!/usr/bin/env bash
# tests/gramax/cross-catalog-retraction/ac-007-plugin-json-version.sh
# Требование: docs/30-requirements/2026-08-13-cross-catalog-retraction.md, AC-007 (FR-102).
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
      # qa-057 F9a (PM): релизный литерал «4.2.1» ретирирован — пин релизного момента
      # волны 4.2.1 ротился на каждом последующем релизе (4.3.0/4.4.0/4.5.0; протух на
      # 5f64966). Живой контракт в ретроспективе — инвариант синхронизации релиза:
      # версия plugin.json существует, semver, и совпадает с marketplace.metadata.version
      # (релизная реальность по qa-057: 4.5.0 == 4.5.0). Литерал 4.2.1 остаётся в RECORD
      # отчёта волны 4.2.1
      # (docs/60-implementation/test-reports/2026-08-13-cross-catalog-retraction-qa-report.md).
      MARKET_VERSION="$(jq -r '.metadata.version' "$ROOT/.claude-plugin/marketplace.json" 2>/dev/null)"
      if ! printf '%s' "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "  FAIL: AC-007 — версия '$VERSION' не semver (X.Y.Z) — plugin.json повреждён" >&2
        FAIL=$((FAIL + 1))
      elif [ "$MARKET_VERSION" != "$VERSION" ]; then
        echo "  FAIL: AC-007 — рассинхрон версий релиза: plugin.json=$VERSION, marketplace.json=$MARKET_VERSION — bump обязан быть синхронным (ADR-0017 Решение 3)" >&2
        FAIL=$((FAIL + 1))
      fi
    fi
  fi
fi

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-007: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-007: plugin.json version semver и синхронна с marketplace.json"
