#!/usr/bin/env bash
# tests/gramax/nauta-integration/ac-007-no-stale-doc-paths.sh
# Spec: docs/superpowers/specs/2026-08-07-nauta-integration-design.md FR-10
# AC coverage:
#   AC-14 → нет ссылок на docs/adr, docs/qa-reports, docs/acceptance, docs/research
#   AC-14 → нет ссылок на четыре переехавшие спеки docs/superpowers/specs/<файл>.md
#     (diagram-on-demand-design, remove-diagram-skills, routing-mermaid-drawio,
#     mermaid-file-based-design — переехали в content/30-requirements/ задачей 6).
#     Паттерн — полные имена файлов, не префикс docs/superpowers/specs/: тот же префикс
#     несёт apply-project-template-design.md и nauta-integration-design.md, чьи пути
#     верны и остаются в docs/ по AC-5.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"
cd "$ROOT"

FAIL=0
PATTERN_DIRS='docs/(adr|qa-reports|acceptance|research)'
PATTERN_SPECS='docs/superpowers/specs/(2026-05-08-diagram-on-demand-design|2026-05-11-remove-diagram-skills|2026-05-11-routing-mermaid-drawio|2026-05-12-mermaid-file-based-design)\.md'

# scripts/ вне области: доставленные sync-scripts валидаторы — чужие файлы под управлением
# .nauta-scripts-basis.yaml (validate-content.py несёт "docs/adr/" в собственном комментарии),
# править их нельзя. tests/gramax/nauta-integration/ исключён: этот suite обязан называть
# старые пути в ассертах их отсутствия.
HITS_DIRS="$(grep -rnE "$PATTERN_DIRS" \
  --include='*.md' --include='*.sh' --include='*.json' \
  plugins tests CLAUDE.md AGENTS.md README.md 2>/dev/null \
  | grep -v '^tests/gramax/nauta-integration/' || true)"

if [ -n "$HITS_DIRS" ]; then
  echo "  FAIL: AC-14: остались ссылки на переехавшие каталоги (docs/adr|qa-reports|acceptance|research):" >&2
  echo "$HITS_DIRS" | head -20 >&2
  FAIL=$((FAIL + 1))
fi

HITS_SPECS="$(grep -rnE "$PATTERN_SPECS" \
  --include='*.md' --include='*.sh' --include='*.json' \
  plugins tests CLAUDE.md AGENTS.md README.md 2>/dev/null \
  | grep -v '^tests/gramax/nauta-integration/' || true)"

if [ -n "$HITS_SPECS" ]; then
  echo "  FAIL: AC-14: остались ссылки на переехавшие спеки (docs/superpowers/specs/<файл>.md, задача 6):" >&2
  echo "$HITS_SPECS" | head -20 >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-007: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-007: ссылок на старые пути docs/ не осталось"
