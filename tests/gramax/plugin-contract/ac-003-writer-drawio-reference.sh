#!/usr/bin/env bash
# tests/gramax/plugin-contract/ac-003-writer-drawio-reference.sh
# Требование: FR-008. Происхождение: archive/remove-diagram-skills ac-008 (структурная часть).
# Природа: regression guard — зелёный на момент создания.

set -e -u -o pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
source "$SCRIPT_DIR/lib/assert.sh"

FAIL=0
REF="$ROOT/plugins/gramax/skills/writer/references/drawio.md"

assert_file_exists "$REF" "FR-008: writer/references/drawio.md должен существовать"
assert_grep "$REF" "Prerequisites"      "FR-008: секция Prerequisites"
assert_grep "$REF" "draw.io desktop"    "FR-008: упоминание draw.io desktop"
assert_grep_regex "$REF" 'Python 3|python3' "FR-008: упоминание Python 3"
assert_grep "$REF" "/plugin marketplace add Agents365-ai/365-skills" \
  "FR-008: команда установки marketplace"
assert_grep "$REF" "/plugin install drawio" "FR-008: команда установки плагина"
assert_grep_regex "$REF" 'двухшаговый|Двухшаговый|Шаг 1' "FR-008: описание двухшагового workflow"
assert_grep_regex "$REF" 'не вставляет|не знает|doc-root' \
  "FR-008: примечание, что drawio-skill не вставляет тег сам"

if [ "$FAIL" -gt 0 ]; then fail_msg "ac-003: $FAIL assertion(s) failed"; exit 1; fi
pass_msg "ac-003: структура writer/references/drawio.md соблюдена"
