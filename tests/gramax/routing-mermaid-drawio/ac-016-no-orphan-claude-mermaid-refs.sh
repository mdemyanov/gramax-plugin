#!/usr/bin/env bash
# tests/gramax/routing-mermaid-drawio/ac-016-no-orphan-claude-mermaid-refs.sh
# Spec: docs/superpowers/specs/2026-05-11-routing-mermaid-drawio.md
# ADR: docs/adr/0009-drawio-stub-and-claude-mermaid-removal.md (Решение 2 пункт 8, RISK-002)
# AC coverage:
#   Sunset pattern (не в spec, но обязателен при удалении публичного компонента):
#   ни один оставшийся файл плагина НЕ ссылается на «claude-mermaid»,
#   за исключением исторических локаций: docs/adr/, docs/superpowers/
#
# Допустимые упоминания: ADR-0009, spec 2026-05-11, прошлые CHANGELOG-секции (до 3.0.0).
# Недопустимые: plugins/gramax/skills/, plugins/gramax/.claude-plugin/,
#               README.md (корневой + плагина), AGENTS.md, корневой CHANGELOG.md
#
# TDD stub: ПАДАЕТ пока Dev не вычистит orphan-ссылки (ADR-0009 пункт 8 списка изменений).

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
PATTERN="claude-mermaid"

# Paths that must NOT contain claude-mermaid references
FORBIDDEN_PATHS=(
  "$ROOT/plugins/gramax/skills"
  "$ROOT/plugins/gramax/.claude-plugin"
  "$ROOT/README.md"
  "$ROOT/plugins/gramax/README.md"
  "$ROOT/AGENTS.md"
  "$ROOT/CHANGELOG.md"
  "$ROOT/.claude-plugin/marketplace.json"
)

# Add agents dir if exists
if [ -d "$ROOT/plugins/gramax/agents" ]; then
  FORBIDDEN_PATHS+=("$ROOT/plugins/gramax/agents")
fi

TOTAL_MATCHES=0
for path in "${FORBIDDEN_PATHS[@]}"; do
  if [ -e "$path" ]; then
    MATCHES=$((grep -rn "$PATTERN" "$path" 2>/dev/null || true) | wc -l | tr -d ' ')
    if [ "$MATCHES" -gt 0 ]; then
      echo "  FAIL: AC-016: $MATCHES orphan 'claude-mermaid' reference(s) in $path:" >&2
      (grep -rn "$PATTERN" "$path" 2>/dev/null || true) | head -10 >&2
      TOTAL_MATCHES=$((TOTAL_MATCHES + MATCHES))
    fi
  fi
done

if [ "$TOTAL_MATCHES" -gt 0 ]; then
  echo "" >&2
  echo "  AC-016 total: $TOTAL_MATCHES orphan reference(s) to removed 'claude-mermaid'" >&2
  echo "  Allowed locations (not checked here): docs/adr/, docs/superpowers/" >&2
  FAIL=$((FAIL + 1))
fi

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-016: $FAIL assertion(s) failed ($TOTAL_MATCHES orphan refs)"
  exit 1
fi
pass_msg "ac-016: no orphan 'claude-mermaid' references in plugin files and root docs"
