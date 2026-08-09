#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-004-readme-prerequisites-warning.sh
# Требование: FR-009. Происхождение: archive/remove-diagram-skills ac-009.
# Природа: живой контракт. КРАСНЫЙ до FR-019 — WARNING по ADR-0008 Решение 6 не был добавлен.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
README="$ROOT/plugins/gramax/README.md"

assert_file_exists "$README" "FR-009: plugins/gramax/README.md должен существовать"
assert_grep "$README" "draw.io desktop" "FR-009: prerequisites — draw.io desktop"
assert_grep "$README" "/plugin marketplace add Agents365-ai/365-skills" \
  "FR-009: prerequisites — команда marketplace"
assert_grep "$README" "/plugin install drawio" "FR-009: prerequisites — команда install"
assert_grep_regex "$README" 'Python 3|python3|repair_png' "FR-009: prerequisites — Python 3"

# ADR-0008 Решение 6: предупреждение о конфликте триггеров с чужим mermaid-skill
assert_grep_regex "$README" 'Warning|WARNING|Предупреждение' \
  "FR-009: README обязан нести WARNING о конфликте с Agents365-ai/mermaid-skill"
assert_grep "$README" "mermaid-skill" \
  "FR-009: WARNING обязан называть конфликтующий skill поимённо"
assert_grep_regex "$README" 'недетерминирован' \
  "FR-009: WARNING обязан объяснять последствие — недетерминированный выбор skill'а"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-004: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-004: README несёт prerequisites и WARNING по ADR-0008 Решение 6"
