#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-10
# AC coverage:
#   AC-14 → нет ссылок на docs/adr, docs/qa-reports, docs/acceptance, docs/research

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0
PATTERN='docs/(adr|qa-reports|acceptance|research)'

# scripts/ вне области: доставленные sync-scripts валидаторы — чужие файлы под управлением
# .nauta-scripts-basis.yaml (validate-content.py несёт "docs/adr/" в собственном комментарии),
# править их нельзя. tests/gramax/nauta-integration/ исключён: этот suite обязан называть
# старые пути в ассертах их отсутствия.
HITS="$(grep -rnE "$PATTERN" \
  --include='*.md' --include='*.sh' --include='*.json' \
  plugins tests CLAUDE.md AGENTS.md README.md 2>/dev/null \
  | grep -v '^tests/gramax/nauta-integration/' || true)"

if [ -n "$HITS" ]; then
  echo "  FAIL: AC-14: остались ссылки на переехавшие каталоги:" >&2
  echo "$HITS" | head -20 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-007: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-007: ссылок на старые пути docs/ не осталось"
