#!/usr/bin/env bash
# tests/gramax/remove-diagram-skills/ac-014-mermaid-description-updated.sh
# Spec: docs/superpowers/specs/2026-05-11-remove-diagram-skills.md
# ADR: docs/adr/0008-drop-internal-drawio-skills.md Решение 5
# AC coverage:
#   AC-014 → plugins/gramax/skills/mermaid/SKILL.md description в frontmatter:
#             (a) явно ограничивает scope mermaid DSL-кейсами
#             (b) содержит упоминание делегирования drawio внешнему плагину
#             (c) НЕ упоминает drawio как кейс применения данного skill'а
#
# TDD stub: должен ПАДАТЬ пока Dev не уточнит description mermaid/SKILL.md.
#
# ВАЖНО: проверка (c) — нетривиальная. Допустимо упоминать drawio в контексте
# «не для drawio» или «для drawio используй ...». Поэтому проверяем на
# положительные маркеры ADR-0008 Решение 5, а не просто отсутствие слова.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0

MERMAID_SKILL="$ROOT/plugins/gramax/skills/mermaid/SKILL.md"

assert_file_exists "$MERMAID_SKILL" \
  "AC-014: plugins/gramax/skills/mermaid/SKILL.md must exist"

# Extract frontmatter description field (everything between first --- and second ---)
# and check markers from ADR-0008 Решение 5

FRONTMATTER="$(python3 - "$MERMAID_SKILL" <<'EOF'
import re, sys
content = open(sys.argv[1]).read()
m = re.search(r'^---\s*\n(.+?)\n---', content, re.DOTALL)
if m:
    print(m.group(1))
else:
    print("")
EOF
)"

DESCRIPTION="$(echo "$FRONTMATTER" | grep -E "^description:" | head -1 || echo "")"

# (a) Frontmatter must have a description field
if [ -z "$DESCRIPTION" ]; then
  echo "  FAIL: AC-014: mermaid/SKILL.md has no 'description:' in frontmatter" >&2
  FAIL=$((FAIL + 1))
fi

# (a) Must explicitly restrict to Mermaid DSL
if ! echo "$DESCRIPTION" | grep -qiE "Mermaid DSL|синтаксис Mermaid|только для.*Mermaid|mermaid.*только"; then
  echo "  FAIL: AC-014: description must explicitly restrict to 'Mermaid DSL' (ADR-0008 Решение 5)" >&2
  echo "  Actual description: $DESCRIPTION" >&2
  FAIL=$((FAIL + 1))
fi

# (b) Must mention drawio delegation to external plugin
if ! echo "$DESCRIPTION" | grep -qiE "Agents365-ai|drawio-skill|внешний.*drawio|drawio.*внешний"; then
  echo "  FAIL: AC-014: description must mention drawio delegation to external plugin (ADR-0008 Решение 5)" >&2
  echo "  Actual description: $DESCRIPTION" >&2
  FAIL=$((FAIL + 1))
fi

# (c) Body of SKILL.md must have explicit 'Не для' / 'Not for' section mentioning drawio
assert_grep_regex "$MERMAID_SKILL" "(Не для|Not for)" \
  "AC-014: mermaid/SKILL.md must have 'Не для' section"

assert_grep_regex "$MERMAID_SKILL" "drawio" \
  "AC-014: mermaid/SKILL.md must mention drawio (in 'Не для' context)"

if [ "$FAIL" -gt 0 ]; then
  fail_msg "ac-014: $FAIL assertion(s) failed"
  exit 1
fi
pass_msg "ac-014: mermaid/SKILL.md description restricts to Mermaid DSL and delegates drawio"
